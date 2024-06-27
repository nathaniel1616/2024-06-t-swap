// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { TSwapPool } from "../../src/PoolFactory.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { PoolFactory } from "../../src/PoolFactory.sol";
import { StdInvariant } from "forge-std/StdInvariant.sol";
import { Handler } from "./Handler.t.sol";

contract HandlerInvariantTest is StdInvariant, Test {
    TSwapPool pool;
    ERC20Mock poolToken;
    ERC20Mock weth;
    Handler handler;
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
        handler = new Handler(pool, poolToken, weth);

        weth.mint(liquidityProvider, LP_STARTING_BALANCE);
        poolToken.mint(liquidityProvider, LP_STARTING_BALANCE);

        weth.mint(user, USER_STARTING_BALANCE);
        poolToken.mint(user, USER_STARTING_BALANCE);

        /// TODO: add invariant target contract
        targetContract(address(handler));
        // targetSender(address(user));
        targetSender(address(liquidityProvider));
    }

    function invariant_LPCanDepositHander() public {
        uint256 wethBalanceOfLiquidProvider = weth.balanceOf(liquidityProvider);
        uint256 poolTokenBalanceOfLiquidProvider = poolToken.balanceOf(liquidityProvider);
        console.log("wethBalanceOfLiquidProvider", wethBalanceOfLiquidProvider);
        console.log("number of deposits", handler.countLpDeposit());
        assertEq(weth.balanceOf(address(pool)), LP_STARTING_BALANCE - wethBalanceOfLiquidProvider);
    }
}
