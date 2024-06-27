// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { TSwapPool } from "../../src/PoolFactory.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { PoolFactory } from "../../src/PoolFactory.sol";
import { StdInvariant } from "forge-std/StdInvariant.sol";

contract OpenInvariantTest is StdInvariant, Test {
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

    function setUp() external {
        poolToken = new ERC20Mock();
        weth = new ERC20Mock();
        pool = new TSwapPool(address(poolToken), address(weth), "LTokenA", "LA");
        MINIMUM_WETH_DEPOSIT = pool.getMinimumWethDepositAmount();

        weth.mint(liquidityProvider, LP_STARTING_BALANCE);
        poolToken.mint(liquidityProvider, LP_STARTING_BALANCE);

        weth.mint(user, USER_STARTING_BALANCE);
        poolToken.mint(user, USER_STARTING_BALANCE);

        /// TODO: add invariant target contract
        targetContract(address(pool));
        targetSender(address(user));
    }

    function invariant_LPDepositStayTheSAme() public {
        assertEq(poolToken.balanceOf(liquidityProvider), LP_STARTING_BALANCE);
    }

    function invariant_LPCanWithWithDraw() public {
        uint256 lpDeposit = LP_INITIAL_DEPOSIT;
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

    function invariant_UserCanSwap() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), LP_INITIAL_DEPOSIT);
        poolToken.approve(address(pool), LP_INITIAL_DEPOSIT);
        pool.deposit(LP_INITIAL_DEPOSIT, LP_INITIAL_DEPOSIT, LP_INITIAL_DEPOSIT, uint64(block.timestamp));
        vm.stopPrank();
        uint256 userAmount = USER_STARTING_BALANCE / 1000;
        userAmount = bound(userAmount, 1, USER_STARTING_BALANCE / 1000);
        vm.startPrank(user);
        poolToken.approve(address(pool), userAmount);
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
}
