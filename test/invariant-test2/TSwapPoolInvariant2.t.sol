// SPDX License-Identifier: MIT
pragma solidity ^0.8.0;

import {TSwapPool} from "src/TSwapPool.sol";
import {PoolFactory} from "src/PoolFactory.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test, console} from "forge-std/Test.sol";

// imports from Openzeppelin
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

// import token from "test/mock"
import {WETH} from "test/mock/WETH.sol";
import {PoolToken} from "test/mock/PoolToken.sol";

// import Hanlder2
import {Handler2} from "test/invariant-test2/Handler2.t.sol";

contract TSwapPoolInvariant2 is StdInvariant, Test {
    // libraries imports
    using SafeERC20 for IERC20;

    // state variables, constants
    TSwapPool public pool;
    PoolFactory public factory;
    WETH public weth;
    PoolToken public poolToken;
    uint256 public constant STARTING_TOKEN_BALANCE = 100e24;
    uint256 public constant AMOUNT_TO_DEPOSIT = 10e24;
    address liquidityProvider = makeAddr("liquidityProvider");
    Handler2 hanlder2;

    function setUp() public {
        weth = new WETH();
        poolToken = new PoolToken();
        factory = new PoolFactory(address(weth));
        pool = new TSwapPool(address(poolToken), address(weth), "T-Swap", "ts");
        // the test contract will act as the First LP in the pool
        vm.startPrank(liquidityProvider);
        weth.mint(liquidityProvider, STARTING_TOKEN_BALANCE);
        poolToken.mint(liquidityProvider, STARTING_TOKEN_BALANCE);
        weth.approve(address(pool), STARTING_TOKEN_BALANCE);
        poolToken.approve(address(pool), STARTING_TOKEN_BALANCE);
        pool.deposit(
            AMOUNT_TO_DEPOSIT,
            AMOUNT_TO_DEPOSIT,
            AMOUNT_TO_DEPOSIT,
            uint64(block.timestamp)
        );
        vm.stopPrank();

        hanlder2 = new Handler2(pool, address(weth));
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = hanlder2.depositLp.selector;
        selectors[1] = hanlder2.swapWethForPoolToken.selector;

        targetSelector(
            FuzzSelector({addr: address(hanlder2), selectors: selectors})
        );
        targetContract(address(hanlder2));
    }

    function testLPFirstDeposit() public {
        // assertEq(
        //     poolToken.balanceOf(liquidityProvider),
        //     STARTING_TOKEN_BALANCE - AMOUNT_TO_DEPOSIT
        // );
        assertEq(pool.balanceOf(liquidityProvider), AMOUNT_TO_DEPOSIT);
    }

    function invariant__hander2works() public {
        // assertGe(pool.balanceOf(liquidityProvider), AMOUNT_TO_DEPOSIT);
        assert(pool.balanceOf(liquidityProvider) == AMOUNT_TO_DEPOSIT);
        console.log("total pool balance", weth.balanceOf(address(pool)));
        console.log("number of Lpdeposits: ", hanlder2.countLpDeposits());
        console.log("number of Swaps", hanlder2.countSWaps());
    }

    function invariant__constantProductFormulaStaySame() public {
        // assertEq(hanlder2.actualDeltaX(), hanlder2.expectedDeltaX());
        assertEq(hanlder2.actualDeltaY(), hanlder2.expectedDeltaY());
    }
}
