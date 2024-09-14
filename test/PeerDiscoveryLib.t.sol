// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {PeerDiscoverLib} from "../src/PeerDiscoveryLib.sol";

contract PeerDiscoveryLibTest is Test {
    using PeerDiscoverLib for *;

    function setUp() public {}

    function test_SomeFunction() public {
        assertTrue(true);
    }
}
