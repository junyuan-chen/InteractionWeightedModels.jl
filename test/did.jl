@testset "RegressionBasedDID" begin
    hrs = exampledata("hrs")

    r = @did(Reg, data=hrs, dynamic(:wave, -1), notyettreated(11),
        vce=Vcov.cluster(:hhidpn), yterm=term(:oop_spend), treatname=:wave_hosp,
        treatintterms=(), xterms=(fe(:wave)+fe(:hhidpn)))
    @test coef(r, "wave_hosp: 8 & rel: 0") ≈ 2825.5659 atol=1e-4
    @test coef(r, "wave_hosp: 8 & rel: 1") ≈ 825.14585 atol=1e-5
    @test coef(r, "wave_hosp: 8 & rel: 2") ≈ 800.10647 atol=1e-5
    @test coef(r, "wave_hosp: 9 & rel: -2") ≈ 298.97735 atol=1e-5
    @test coef(r, "wave_hosp: 9 & rel: 0") ≈ 3030.8408 atol=1e-4
    @test coef(r, "wave_hosp: 9 & rel: 1") ≈ 106.83785 atol=1e-5
    @test coef(r, "wave_hosp: 10 & rel: -3") ≈ 591.04639 atol=1e-5
    @test coef(r, "wave_hosp: 10 & rel: -2") ≈ 410.58102 atol=1e-5
    @test coef(r, "wave_hosp: 10 & rel: 0") ≈ 3091.5084 atol=1e-4

    @test nobs(r) == 2624
    
    @test sprint(show, r) == "Regression-based DID result"
    pv = VERSION < v"1.7.0-DEV" ? " <1e-5" : "<1e-05"
    @test sprint(show, MIME("text/plain"), r) == """
        ──────────────────────────────────────────────────────────────────────
        Summary of results: Regression-based DID
        ──────────────────────────────────────────────────────────────────────
        Number of obs:               2624    Degrees of freedom:           670
        F-statistic:                 4.81    p-value:                   $pv
        ──────────────────────────────────────────────────────────────────────
        Cohort-interacted sharp dynamic specification
        ──────────────────────────────────────────────────────────────────────
        Number of cohorts:              3    Interactions within cohorts:    0
        Relative time periods:          5    Excluded periods:              -1
        ──────────────────────────────────────────────────────────────────────
        Fixed effects: fe_hhidpn fe_wave
        ──────────────────────────────────────────────────────────────────────
        Converged:                   true    Singletons dropped:             0
        ──────────────────────────────────────────────────────────────────────"""

    r = @did(Reg, data=hrs, dynamic(:wave, -1), notyettreated([11]),
        vce=Vcov.cluster(:hhidpn), yterm=term(:oop_spend), treatname=:wave_hosp,
        treatintterms=(), cohortinteracted=false)
    @test sprint(show, MIME("text/plain"), r) == """
        ──────────────────────────────────────────────────────────────────────
        Summary of results: Regression-based DID
        ──────────────────────────────────────────────────────────────────────
        Number of obs:               2624    Degrees of freedom:             6
        F-statistic:                12.50    p-value:                   <1e-10
        ──────────────────────────────────────────────────────────────────────
        Sharp dynamic specification
        ──────────────────────────────────────────────────────────────────────
        Relative time periods:          5    Excluded periods:              -1
        ──────────────────────────────────────────────────────────────────────
        Fixed effects: none
        ──────────────────────────────────────────────────────────────────────"""
end

@testset "@specset" begin
    hrs = exampledata("hrs")
    # The first two specs are identical hence no repetition of steps should occur
    # The third spec should only share the first three steps with the others
    r = @specset [verbose] begin
        @did(Reg, dynamic(:wave, -1), notyettreated(11), data=hrs,
            yterm=term(:oop_spend), treatname=:wave_hosp, treatintterms=(),
            xterms=(fe(:wave)+fe(:hhidpn)))
        @did(Reg, dynamic(:wave, -1), notyettreated(11), data=hrs,
            yterm=term(:oop_spend), treatname=:wave_hosp, treatintterms=[],
            xterms=[fe(:hhidpn), fe(:wave)])
        @did(Reg, dynamic(:wave, -1), nevertreated(11), data=hrs,
            yterm=term(:oop_spend), treatname=:wave_hosp, treatintterms=(),
            xterms=(fe(:wave)+fe(:hhidpn)))
    end
    @test r[1] == didspec(Reg, dynamic(:wave, -1), notyettreated(11), data=hrs,
        yterm=term(:oop_spend), treatname=:wave_hosp, treatintterms=(),
        xterms=TermSet(fe(:wave), fe(:hhidpn)))()
end
