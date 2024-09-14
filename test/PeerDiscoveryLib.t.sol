// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {PeerDiscoveryLib} from "../src/PeerDiscoveryLib.sol";

contract PeerDiscoveryLibTest is Test {
    using PeerDiscoveryLib for mapping(address => PeerDiscoveryLib.PeerInfo);

    mapping(address => PeerDiscoveryLib.PeerInfo) peers;
    address constant VALID_PEER = address(0x1);
    string constant VALID_IP = "192.168.1.1";
    uint16 constant VALID_PORT = 8080;
    string[] VALID_PROTOCOLS;

    function setUp() public {
        VALID_PROTOCOLS = new string[](2);
        VALID_PROTOCOLS[0] = "http";
        VALID_PROTOCOLS[1] = "https";
    }

    function test_AddPeer() public {
        peers.addPeer(VALID_PEER, VALID_IP, VALID_PORT, VALID_PROTOCOLS);
        assertTrue(peers.isPeer(VALID_PEER), "Peer should be added successfully");
    }

    function test_AddPeer_RevertPeerAlreadyExists() public {
        peers.addPeer(VALID_PEER, VALID_IP, VALID_PORT, VALID_PROTOCOLS);
        vm.expectRevert(PeerDiscoveryLib.PeerAlreadyExists.selector);
        peers.addPeer(VALID_PEER, VALID_IP, VALID_PORT, VALID_PROTOCOLS);
        assertTrue(peers.isPeer(VALID_PEER), "Peer should still exist");
    }

    function test_UpdatePeer() public {
        peers.addPeer(VALID_PEER, VALID_IP, VALID_PORT, VALID_PROTOCOLS);
        string memory newIp = "10.0.0.1";
        uint16 newPort = 9090;
        peers.updatePeer(VALID_PEER, newIp, newPort, VALID_PROTOCOLS);
        (string memory ip, uint16 port,) = peers.getPeerInfo(VALID_PEER);
        assertEq(ip, newIp, "IP should be updated");
        assertEq(port, newPort, "Port should be updated");
    }

    function test_UpdatePeer_RevertPeerDoesNotExist() public {
        vm.expectRevert(PeerDiscoveryLib.PeerDoesNotExist.selector);
        peers.updatePeer(VALID_PEER, VALID_IP, VALID_PORT, VALID_PROTOCOLS);
        assertFalse(peers.isPeer(VALID_PEER), "Peer should not exist");
    }

    function test_RemovePeer() public {
        peers.addPeer(VALID_PEER, VALID_IP, VALID_PORT, VALID_PROTOCOLS);
        peers.removePeer(VALID_PEER);
        assertFalse(peers.isPeer(VALID_PEER), "Peer should be removed");
    }

    function test_RemovePeer_RevertPeerDoesNotExist() public {
        vm.expectRevert(PeerDiscoveryLib.PeerDoesNotExist.selector);
        peers.removePeer(VALID_PEER);
        assertFalse(peers.isPeer(VALID_PEER), "Peer should not exist");
    }

    function test_GetPeerInfo() public {
        peers.addPeer(VALID_PEER, VALID_IP, VALID_PORT, VALID_PROTOCOLS);
        (string memory ip, uint16 port, string[] memory protocols) = peers.getPeerInfo(VALID_PEER);
        assertEq(ip, VALID_IP, "IP should match");
        assertEq(port, VALID_PORT, "Port should match");
        assertEq(protocols.length, VALID_PROTOCOLS.length, "Protocol length should match");
        assertEq(protocols[0], VALID_PROTOCOLS[0], "First protocol should match");
        assertEq(protocols[1], VALID_PROTOCOLS[1], "Second protocol should match");
    }

    function test_GetPeerInfo_RevertPeerInfoNotInitialized() public {
        vm.expectRevert(PeerDiscoveryLib.PeerInfoNotInitialized.selector);
        peers.getPeerInfo(VALID_PEER);
        assertFalse(peers.isPeer(VALID_PEER), "Peer should not exist");
        console.log("Get peer info revert successful for uninitialized peer: ", VALID_PEER);
    }

    function test_ValidatePeerInput_RevertInvalidPortNumber() public {
        uint16 invalidPort = 0;
        vm.expectRevert(PeerDiscoveryLib.InvalidPortNumber.selector);
        PeerDiscoveryLib.validatePeerInput(VALID_PEER, VALID_IP, invalidPort, VALID_PROTOCOLS);
        assertFalse(peers.isPeer(VALID_PEER), "Peer should not be added with invalid port");
    }

    function test_ValidatePeerInput_RevertTooManyProtocols() public {
        string[] memory tooManyProtocols = new string[](PeerDiscoveryLib.MAX_PROTOCOLS + 1);
        for (uint256 i = 0; i <= PeerDiscoveryLib.MAX_PROTOCOLS; i++) {
            tooManyProtocols[i] = "protocol";
        }
        vm.expectRevert(PeerDiscoveryLib.TooManyProtocols.selector);
        PeerDiscoveryLib.validatePeerInput(VALID_PEER, VALID_IP, VALID_PORT, tooManyProtocols);
        assertFalse(peers.isPeer(VALID_PEER), "Peer should not be added with too many protocols");
    }

    function test_ValidatePeerInput_RevertIPAddressTooLong() public {
        string memory longIp = new string(PeerDiscoveryLib.MAX_IP_LENGTH + 1);
        vm.expectRevert(PeerDiscoveryLib.IPAddressTooLong.selector);
        PeerDiscoveryLib.validatePeerInput(VALID_PEER, longIp, VALID_PORT, VALID_PROTOCOLS);
        assertFalse(peers.isPeer(VALID_PEER), "Peer should not be added with IP address too long");
    }

    function test_UpdateLastActiveTime() public {
        peers.addPeer(VALID_PEER, VALID_IP, VALID_PORT, VALID_PROTOCOLS);
        uint256 initialTime = peers.getLastActiveTime(VALID_PEER);

        vm.warp(block.timestamp + 1 hours);
        peers.updateLastActiveTime(VALID_PEER, block.timestamp);

        uint256 updatedTime = peers.getLastActiveTime(VALID_PEER);
        assertGt(updatedTime, initialTime, "Last active time should be updated");
        assertEq(
            updatedTime, block.timestamp, "Last active time should match current block timestamp"
        );
    }

    function test_UpdateLastActiveTime_RevertPeerDoesNotExist() public {
        vm.expectRevert(PeerDiscoveryLib.PeerDoesNotExist.selector);
        peers.updateLastActiveTime(VALID_PEER, block.timestamp);
    }

    function test_GetLastActiveTime() public {
        peers.addPeer(VALID_PEER, VALID_IP, VALID_PORT, VALID_PROTOCOLS);

        vm.warp(block.timestamp + 1 hours);
        peers.updateLastActiveTime(VALID_PEER, block.timestamp);

        uint256 lastActiveTime = peers.getLastActiveTime(VALID_PEER);
        assertEq(lastActiveTime, block.timestamp, "Last active time should be updated");
    }

    function test_GetLastActiveTime_RevertPeerDoesNotExist() public {
        vm.expectRevert(PeerDiscoveryLib.PeerDoesNotExist.selector);
        peers.getLastActiveTime(VALID_PEER);
    }
}
