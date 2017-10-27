using ExpectionTestingMocks

using ExpectionTestingMocks: DoNotCare, split_vals_and_sig, ExpectationNotSetError, ExpectationAlreadySetError
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
    @test_throws ExpectationNotSetError foo(5,3)==32
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



@testset "DoNotCare is equal to everything" begin
    @test DoNotCare()==4
    @test 5==DoNotCare()
    @test !(5===DoNotCare())

    @test (Any, DoNotCare()) === (Any,DoNotCare())
    @test !((Any, 1) === (Any,DoNotCare())    )
end


@testset "split_vals_and_sig" begin



    @test split_vals_and_sig([:(::Any)])  == ((DoNotCare(),), :((Any,)))
    @test split_vals_and_sig([:(1::Any)]) == ((1,), :((Any,)))
    @test split_vals_and_sig([:(1)])      == ((1,), :(typeof(1),))
    @test split_vals_and_sig([:(a)])      == ((:a,), :((typeof(a)),))
    @test split_vals_and_sig([:(a::Int)]) == ((:a,), :((Int,)))

    @test split_vals_and_sig([:(a::Int), :(::Integer)]) ==
        ((:a, DoNotCare()), :((Int, Integer)))


end
