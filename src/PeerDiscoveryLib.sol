// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library PeerDiscoverLib {
    struct PeerInfo {
        string ip;
        uint16 port;
        string[] protocols;
        uint256 lastUpdated;
    }

    // Initialize a new PeerInfo struct
    function init(PeerInfo storage self, string memory ip, uint16 port, string[] memory protocols) internal {
        self.ip = ip;
        self.port = port;
        self.protocols = protocols;
        self.lastUpdated = block.timestamp;
    }

    // Update an existing PeerInfo struct
    function update(PeerInfo storage self, string memory ip, uint16 port, string[] memory protocols) internal {
        self.ip = ip;
        self.port = port;
        self.protocols = protocols;
        self.lastUpdated = block.timestamp;
    }

    // Check if the PeerInfo struct is initialized
    function isInitialized(PeerInfo storage self) internal view returns (bool) {
        return bytes(self.ip).length != 0;
    }
}
