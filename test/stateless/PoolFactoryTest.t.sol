// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { PoolFactory } from "../../src/PoolFactory.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract PoolFactoryTest is Test {
    PoolFactory factory;
    ERC20Mock mockWeth;
    ERC20Mock tokenA;
    ERC20Mock tokenB;

    function setUp() public {
        mockWeth = new ERC20Mock();
        factory = new PoolFactory(address(mockWeth));
    }

    function testFuzzCreatePool(ERC20Mock _token) public {
        _token = new ERC20Mock();
        address poolAddress = factory.createPool(address(_token));
        assertEq(poolAddress, factory.getPool(address(_token)));
        assertEq(address(_token), factory.getToken(poolAddress));
    }

    function testFuzzCantCreatePoolIfExists(ERC20Mock _token) public {
        _token = new ERC20Mock();
        console.log(address(_token));
        factory.createPool(address(_token));
        vm.expectRevert(abi.encodeWithSelector(PoolFactory.PoolFactory__PoolAlreadyExists.selector, address(_token)));
        factory.createPool(address(_token));
    }

    ///////////////////////////////////////////////////////////////////////////
    //////                            Audit POC                  //////////////
    ///////////////////////////////////////////////////////////////////////////

    //@ q can you create more than one pool? fuzz
    function testCanCreateManyPools(ERC20Mock _tokenA, ERC20Mock _tokenB) public {
        console.log("hello");
        _tokenA = new ERC20Mock();
        _tokenB = new ERC20Mock();
        console.log("address(_tokenA)", address(_tokenA));
        address poolAddressA = factory.createPool(address(_tokenA));
        address poolAddressB = factory.createPool(address(_tokenB));
        assertEq(address(_tokenA), factory.getToken(poolAddressA));
        assertEq(address(_tokenB), factory.getToken(poolAddressB));
    }
}
