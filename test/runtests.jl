using ExpectionTestingMocks

using ExpectionTestingMocks: DoNotCare, split_vals_and_sig, ExpectationValueMismatchError, ExpectationAlreadySetError
using Base.Test


@testset "basic stubbing" begin
    @stub foo
    @expect(foo(::Any)=32)
    @test foo(3)==32
    @test foo(4)==32
    @test_throws ExpectationAlreadySetError @expect(foo(::Any)=34)
end


@testset "mulitple basic keyed stubs" begin
    @stub foo
    @expect(foo(1)=37)
    @expect(foo(2)=38)
    @test foo(2)==38
    @test foo(1)==37
end

@testset "multi-arg stubbing" begin
    @stub foo
    @expect(foo(4, ::Int)=32)
    @test foo(4,3)==32
    @test_throws ExpectationValueMismatchError foo(5,3)==32
    @test_throws MethodError foo(3,2.0)==32
end

#BROKEN as Mixed keys stubs not currenty allowed.
#can not give a value sometimes but not others
@testset "mixed keyed stubs" begin
    @stub foo
    @expect(foo(1)=30)
    # Throws errors
    #@expect(foo(::Any)=370)
    @test_broken foo(2)==370
    @test foo(1)==30
end

@testset "All expectations used" begin
    @stub foo
    @expect(foo(1)=30)
    @expect(foo(2)=35)

    @test foo(1) == 30
    @test !all_expectations_used(foo)
end

@testset "Expectations used" begin

    @testset "basic" begin
        @stub foo
        @expect(foo(1)=30)
        @expect(foo(2)=35)

        @test foo(1) == 30
        @test @used(foo(1))
        @test !@used(foo(2))
    end

    @testset "mixed" begin
        @stub foo
        @expect(foo(::Int)=310)

        @test foo(105) == 310
        @test @used(foo(105))
        @test @used(foo(::Int))
        @test !@used(foo(2))
        @test !@used(foo(::Bool))
    end

end


@testset "DoNotCare is equal to everything" begin
    @test DoNotCare{Int}()==4
    @test 5==DoNotCare{Integer}()
    @test 5==DoNotCare{Any}()
    @test !(5===DoNotCare{Any}())

    @test 5!=DoNotCare{String}()

    @test (Any, DoNotCare{Any}()) === (Any,DoNotCare{Any}())
    @test !((Any, 1) === (Any,DoNotCare{Int}()))
end
