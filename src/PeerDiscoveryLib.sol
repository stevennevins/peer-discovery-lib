// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {SSTORE2} from "lib/sstore2/contracts/SSTORE2.sol";

library PeerDiscoveryLib {
    uint256 constant MAX_PROTOCOLS = 10;
    uint256 constant MAX_IP_LENGTH = 45;
    uint256 constant MAX_PROTOCOL_LENGTH = 20;

    struct PeerInfo {
        address peerDataPointer;
        uint256 lastActiveTime;
    }

    error PeerAlreadyExists();
    error InvalidPortNumber();
    error PeerDoesNotExist();
    error PeerInfoNotInitialized();
    error TooManyProtocols();
    error InvalidProtocolLength();
    error EmptyProtocol();
    error InvalidPeerKey();
    error IPAddressTooLong();
    error ProtocolStringTooLong();

    function addPeer(
        mapping(address => PeerInfo) storage self,
        address peerKey,
        string memory ip,
        uint16 port,
        string[] memory protocols
    ) internal {
        if (isPeer(self, peerKey)) {
            revert PeerAlreadyExists();
        }
        validatePeerInput(peerKey, ip, port, protocols);

        bytes memory data = abi.encode(ip, port, protocols);
        self[peerKey].peerDataPointer = SSTORE2.write(data);
    }

    function updatePeer(
        mapping(address => PeerInfo) storage self,
        address peerKey,
        string memory ip,
        uint16 port,
        string[] memory protocols
    ) internal {
        if (!isPeer(self, peerKey)) {
            revert PeerDoesNotExist();
        }
        validatePeerInput(peerKey, ip, port, protocols);

        bytes memory data = abi.encode(ip, port, protocols);
        self[peerKey].peerDataPointer = SSTORE2.write(data);
    }

    function removePeer(mapping(address => PeerInfo) storage self, address peerKey) internal {
        if (peerKey == address(0)) {
            revert InvalidPeerKey();
        }
        if (!isPeer(self, peerKey)) {
            revert PeerDoesNotExist();
        }
        delete self[peerKey];
    }

    function isPeer(
        mapping(address => PeerInfo) storage self,
        address peerKey
    ) internal view returns (bool) {
        if (peerKey == address(0)) {
            return false;
        }
        return self[peerKey].peerDataPointer != address(0);
    }

    function getPeerInfo(
        mapping(address => PeerInfo) storage self,
        address peerKey
    ) internal view returns (string memory ip, uint16 port, string[] memory protocols) {
        if (peerKey == address(0)) {
            revert InvalidPeerKey();
        }
        if (!isPeer(self, peerKey)) {
            revert PeerInfoNotInitialized();
        }
        bytes memory data = SSTORE2.read(self[peerKey].peerDataPointer);
        (ip, port, protocols) = abi.decode(data, (string, uint16, string[]));
    }

    function validateProtocols(
        string[] memory protocols
    ) internal pure {
        for (uint256 i = 0; i < protocols.length; i++) {
            if (bytes(protocols[i]).length == 0) {
                revert EmptyProtocol();
            }
            if (bytes(protocols[i]).length > MAX_PROTOCOL_LENGTH) {
                revert ProtocolStringTooLong();
            }
        }
    }

    function validatePeerInput(
        address peerKey,
        string memory ip,
        uint16 port,
        string[] memory protocols
    ) internal pure {
        if (peerKey == address(0)) {
            revert InvalidPeerKey();
        }

        if (port == 0 || port > 65_535) {
            revert InvalidPortNumber();
        }

        if (protocols.length > MAX_PROTOCOLS) {
            revert TooManyProtocols();
        }

        if (bytes(ip).length > MAX_IP_LENGTH) {
            revert IPAddressTooLong();
        }

        validateProtocols(protocols);
    }

    function updateLastActiveTime(
        mapping(address => PeerInfo) storage self,
        address peerKey,
        uint256 time
    ) internal {
        if (!isPeer(self, peerKey)) {
            revert PeerDoesNotExist();
        }
        self[peerKey].lastActiveTime = time;
    }

    function getLastActiveTime(
        mapping(address => PeerInfo) storage self,
        address peerKey
    ) internal view returns (uint256) {
        if (!isPeer(self, peerKey)) {
            revert PeerDoesNotExist();
        }
        return self[peerKey].lastActiveTime;
    }
}
