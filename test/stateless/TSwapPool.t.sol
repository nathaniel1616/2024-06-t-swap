// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { TSwapPool } from "../../src/PoolFactory.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract TSwapPoolTest is Test {
    TSwapPool pool;
    ERC20Mock poolToken;
    ERC20Mock weth;

    address liquidityProvider = makeAddr("liquidityProvider");
    address user = makeAddr("user");
    uint256 public constant LP_STARTING_BALANCE = 200e18;
    uint256 public constant LP_INITIAL_DEPOSIT = 100e18;
    uint256 public constant USER_STARTING_BALANCE = 10e18;
    uint256 public MINIMUM_WETH_DEPOSIT;
    uint256 public constant PRECISION = 1e18;

    function setUp() public {
        poolToken = new ERC20Mock();
        weth = new ERC20Mock();
        pool = new TSwapPool(address(poolToken), address(weth), "LTokenA", "LA");
        MINIMUM_WETH_DEPOSIT = pool.getMinimumWethDepositAmount();

        weth.mint(liquidityProvider, LP_STARTING_BALANCE);
        poolToken.mint(liquidityProvider, LP_STARTING_BALANCE);

        weth.mint(user, USER_STARTING_BALANCE);
        poolToken.mint(user, USER_STARTING_BALANCE);
    }

    function test_fuzzDeposit(uint256 _amount) public {
        uint256 amount = bound(_amount, MINIMUM_WETH_DEPOSIT, LP_INITIAL_DEPOSIT);
        console.log("amount of the fuzz: ", amount);
        console.log("amount of the param: ", _amount);
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), amount);
        poolToken.approve(address(pool), amount);
        pool.deposit(amount, amount, amount, uint64(block.timestamp));
        uint256 LP_ENDING_BALANCE = LP_STARTING_BALANCE - amount;
        assertEq(pool.balanceOf(liquidityProvider), amount);
        assertEq(weth.balanceOf(liquidityProvider), LP_ENDING_BALANCE);
        assertEq(poolToken.balanceOf(liquidityProvider), LP_ENDING_BALANCE);
        assertEq(weth.balanceOf(address(pool)), amount);
        assertEq(poolToken.balanceOf(address(pool)), amount);
    }

    function testFuzzDepositSwap(uint256 _userAmount) public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), LP_INITIAL_DEPOSIT);
        poolToken.approve(address(pool), LP_INITIAL_DEPOSIT);
        pool.deposit(LP_INITIAL_DEPOSIT, LP_INITIAL_DEPOSIT, LP_INITIAL_DEPOSIT, uint64(block.timestamp));
        vm.stopPrank();

        uint256 userAmount = bound(_userAmount, 1, USER_STARTING_BALANCE);
        vm.startPrank(user);
        poolToken.approve(address(pool), userAmount);
        // After we swap, there will be ~110 tokenA, and ~91 WETH
        // 100 * 100 = 10,000
        // 110 * ~91 = 10,000
        //@ audit this calculation above should be check again
        //  y = Token Balance Y
        // x = Token Balance X
        // x * y = k
        // x * y = (x + ∆x) * (y − ∆y)
        // ∆x = Change of token balance X
        // ∆y = Change of token balance Y
        // β = (∆y / y)
        // α = (∆x / x)
        //     Final invariant equation without fees:
        // ∆x = (β/(1-β)) * x
        // ∆y = (α/(1+α)) * y
        uint256 alpha = (userAmount * PRECISION / LP_INITIAL_DEPOSIT);
        console.log("alpha: ", alpha);
        uint256 expected = (alpha * PRECISION / (PRECISION + alpha)) * LP_INITIAL_DEPOSIT / PRECISION;
        console.log("expected: ", expected);
        // we assume 5% fees
        expected = expected * 995 / 1000;
        console.log("expected after fees: ", expected);
        pool.swapExactInput(poolToken, userAmount, weth, expected, uint64(block.timestamp));
        assert(weth.balanceOf(user) >= expected);
    }

    function testFuzzWithdraw(uint256 lpDeposit) public {
        lpDeposit = bound(lpDeposit, MINIMUM_WETH_DEPOSIT, LP_STARTING_BALANCE);
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), lpDeposit);
        poolToken.approve(address(pool), lpDeposit);
        pool.deposit(lpDeposit, lpDeposit, lpDeposit, uint64(block.timestamp));

        pool.approve(address(pool), lpDeposit);
        pool.withdraw(lpDeposit, lpDeposit, lpDeposit, uint64(block.timestamp));

        assertEq(pool.totalSupply(), 0);
        assertEq(weth.balanceOf(liquidityProvider), LP_STARTING_BALANCE);
        assertEq(poolToken.balanceOf(liquidityProvider), LP_STARTING_BALANCE);
    }

    function testCollectFees() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        vm.startPrank(user);
        uint256 expected = 9e18;
        poolToken.approve(address(pool), 10e18);
        pool.swapExactInput(poolToken, 10e18, weth, expected, uint64(block.timestamp));
        vm.stopPrank();

        vm.startPrank(liquidityProvider);
        pool.approve(address(pool), 100e18);
        pool.withdraw(100e18, 90e18, 100e18, uint64(block.timestamp));
        assertEq(pool.totalSupply(), 0);
        assert(weth.balanceOf(liquidityProvider) + poolToken.balanceOf(liquidityProvider) > 400e18);
    }
}
