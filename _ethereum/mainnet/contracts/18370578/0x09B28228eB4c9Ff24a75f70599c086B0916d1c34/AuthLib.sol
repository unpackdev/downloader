// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library AuthLib {
    struct authData {
        bool initialized;
        uint256 ownerCount;
        mapping(address => bool) owners;
        mapping(string => mapping(address => bool)) approvals;
        address[] ownerAddresses;
        mapping(address => uint256) potentialOwnerVotes;
        mapping(address => mapping(address => bool)) removeOwnerVotes;
    }

    function init(authData storage self, address[] memory owners) public {
        require(!self.initialized, "Already initialized");
        self.initialized = true;
        require(owners.length > 0, "Owner list cannot be empty");
        for (uint256 i = 0; i < owners.length; i++) {
            require(owners[i] != address(0), "Owner address cannot be zero");
            if (!self.owners[owners[i]]) {
                self.owners[owners[i]] = true;
                self.ownerCount++;
            }
        }
    }

    function voteNewOwner(authData storage self, address owner)
        public
        onlyOwner(self)
    {
        require(!self.owners[owner], "Address is already an owner");
        self.potentialOwnerVotes[owner]++;

        if (self.potentialOwnerVotes[owner] >= self.ownerCount / 2) {
            self.owners[owner] = true;
            self.ownerCount++;
            self.ownerAddresses.push(owner);
            delete self.potentialOwnerVotes[owner];
        }
    }

    function removeOwner(authData storage self, address ownerToRemove)
        public
        onlyOwner(self)
    {
        require(self.owners[ownerToRemove], "Provided address is not an owner");
        require(
            !self.removeOwnerVotes[ownerToRemove][msg.sender],
            "You have already voted for removal"
        );

        self.removeOwnerVotes[ownerToRemove][msg.sender] = true;
        self.potentialOwnerVotes[ownerToRemove]++;

        if (self.potentialOwnerVotes[ownerToRemove] * 2 > self.ownerCount) {
            self.owners[ownerToRemove] = false;
            self.ownerCount--;
            delete self.potentialOwnerVotes[ownerToRemove];

            for (uint256 i = 0; i < self.ownerAddresses.length; i++) {
                if (self.ownerAddresses[i] == ownerToRemove) {
                    self.ownerAddresses[i] = self.ownerAddresses[
                        self.ownerAddresses.length - 1
                    ];
                    self.ownerAddresses.pop();
                    break;
                }
                self.removeOwnerVotes[ownerToRemove][
                    self.ownerAddresses[i]
                ] = false;
            }
        }
    }

    function authorize(authData storage self, string memory functionName)
        public
        onlyOwner(self)
    {
        require(
            !self.approvals[functionName][msg.sender],
            "You have already authorized this function"
        );
        self.approvals[functionName][msg.sender] = true;
    }

    function clearAuth(authData storage self, string memory functionName)
        internal
    {
        for (uint256 i = 0; i < self.ownerAddresses.length; i++) {
            if (self.approvals[functionName][self.ownerAddresses[i]]) {
                delete self.approvals[functionName][self.ownerAddresses[i]];
            }
        }
    }

    function requireAuth(authData storage self, string memory functionName)
        public
        view
    {
        uint256 approvalCount;
        for (uint256 i = 0; i < self.ownerAddresses.length; i++) {
            if (self.approvals[functionName][self.ownerAddresses[i]]) {
                approvalCount++;
            }
        }
        require(
            approvalCount * 2 >= self.ownerCount,
            "Function not authorized by enough owners"
        );
    }

    function isOwner(authData storage self) public view returns (bool) {
        return self.owners[msg.sender];
    }

    modifier onlyOwner(authData storage self) {
        require(self.owners[msg.sender], "You are not an owner");
        _;
    }
}