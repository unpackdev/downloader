// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import "./Ownable.sol";


interface ICubes {
    function mintByPack(address owner) external;
}


contract InterPack is Ownable {
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier onlyCollaborator() {
        bool isCollaborator = false;
        for (uint256 i; i < collaborators.length; i++) {
            if (collaborators[i].addr == msg.sender) {
                isCollaborator = true;

                break;
            }
        }

        require(
            owner() == _msgSender() || isCollaborator,
            "Ownable: caller is not the owner nor a collaborator"
        );

        _;
    }

    modifier mintStarted() {
        require(
            (startRegularMintDate != 0 && startRegularMintDate <= block.timestamp),
            "You are too early"
        );

        _;
    }

    
    uint256 private startRegularMintDate = 1632952800; // 29.09.2021 22:00 UTC

    uint256 private claimPrice = 90000000000000000;

    
    uint256 private totalTokens = 8116;
    uint256 private totalMintedTokens = 0;


    uint128 private basisPoints = 10000;
    
    uint16 private maxRegularClaimsPerWallet = 20;
    
    mapping(address => uint256) private claimedTokenPerWallet;
    
    
    struct Collaborators {
        address addr;
        uint256 cut;
    }
    
    Collaborators[] internal collaborators;
    
    address private packContractAddress;
    address private cubesContractAddress;
    
    struct Holder { 
       bool set;
       uint8 minted;
    }
    
    mapping(address => Holder) private mintpassHolders;
    uint256 private mintpassHoldersCurrentSize = 0;
    uint8 private maxFreeSetsPerHolder = 1;
    

    
    // ONLY OWNER

    /**
     * Sets the collaborators of the project with their cuts
     */
    function addCollaborators(Collaborators[] memory _collaborators)
        external
        onlyOwner
    {
        require(collaborators.length == 0, "Collaborators were already set");

        uint128 totalCut;
        for (uint256 i; i < _collaborators.length; i++) {
            collaborators.push(_collaborators[i]);
            totalCut += uint128(_collaborators[i].cut);
        }

        require(totalCut == basisPoints, "Total cut does not add to 100%");
    }

    
    
    function setCubesAddr(address _addr) external onlyOwner {
       cubesContractAddress = _addr;
    }
    
    function setPackAddr(address _addr) external onlyOwner {
       packContractAddress = _addr;
    }

    /**
     * @dev Sets the claim price for each token
     */
    function setClaimPrice(uint256 _claimPrice) external onlyOwner {
        claimPrice = _claimPrice;
    }
    
    function setStartRegularMintDate(uint256 _startMintDate) external onlyOwner {
        startRegularMintDate = _startMintDate;
    }
    
    function setTotalTokens(uint256 _num) external onlyOwner {
        require (_num >= totalMintedTokens, "Cannot be less than already minted");
        totalTokens = _num;
    }

    function setMaxPerWallet(uint16 _num) external onlyOwner {
        maxRegularClaimsPerWallet = _num;
    }

    
    function giftSet(address[] calldata _addresses) external onlyOwner {
        require((totalMintedTokens + _addresses.length) <= totalTokens, "No sets left to be minted");

        for (uint i = 0; i < _addresses.length; i++) {
            ICubes(cubesContractAddress).mintByPack(_addresses[i]);
        }
        
        
        totalMintedTokens = totalMintedTokens + _addresses.length;
    }
    
    function addMintpassHolders(address[] calldata _addrs) external onlyOwner {
        require((mintpassHoldersCurrentSize + _addrs.length) <= 1000, 'Max mintpass holders num exceed');
        
        for (uint128 i = 0; i < _addrs.length; i++) {
            mintpassHolders[_addrs[i]] = Holder(true, 0);
        }
        
        mintpassHoldersCurrentSize = mintpassHoldersCurrentSize + _addrs.length;
    }
    
    function setMaxFreeSetsPerholder(uint8 _num) external onlyOwner {
        maxFreeSetsPerHolder = _num;
    }
    
    // ONLY collaborators
    
    /**
     * @dev Allows to withdraw the Ether in the contract and split it among the collaborators
     */
    function withdraw() external onlyCollaborator {
        uint256 totalBalance = address(this).balance;

        for (uint256 i; i < collaborators.length; i++) {
            payable(collaborators[i].addr).transfer(
                mulScale(totalBalance, collaborators[i].cut, basisPoints)
            );
        }
    }


    // END ONLY COLLABORATORS


    
    
    fallback() external payable {}
    
    receive() external payable {}
    
    function getAvailableToMint() external view returns (uint256) {
        return (totalTokens - totalMintedTokens);
    }
    
    function mint(uint8 _numOfPacks) external payable callerIsUser mintStarted {
        require(msg.value >= (claimPrice * _numOfPacks), "Not enough Ether to mint a pack");
        require((totalMintedTokens + _numOfPacks) <= totalTokens, "No packs left to be minted");
        
        require(
            (claimedTokenPerWallet[msg.sender] + _numOfPacks) <= maxRegularClaimsPerWallet,
            "You cannot claim more packs."
        );

        for (uint8 j = 0; j < _numOfPacks; j++) {
            ICubes(cubesContractAddress).mintByPack(msg.sender);
        }
        
        totalMintedTokens = totalMintedTokens + _numOfPacks;
        claimedTokenPerWallet[msg.sender] = claimedTokenPerWallet[msg.sender] + _numOfPacks;
    }
    
    function mintByPack(address owner) external {
        require(msg.sender == packContractAddress, "Unauthorized");
        ICubes(cubesContractAddress).mintByPack(owner);
    }
    
    function claimFreeSet() external {
        
        require(true == mintpassHolders[msg.sender].set, "You are not in the mintpass holder list.");
        require(maxFreeSetsPerHolder > mintpassHolders[msg.sender].minted, "You cannot claim more free sets.");
        
        mintpassHolders[msg.sender].minted++;
        ICubes(cubesContractAddress).mintByPack(msg.sender);
        totalMintedTokens++;
    }
    
    function getMintpassHoldersCurrentSize() external view returns (uint) {
        return mintpassHoldersCurrentSize;
    }
    
    function isAddresRegisterdAsMintpassHolder (address _addr) external view returns (bool) {
        return mintpassHolders[_addr].set;
    }
    
    function getNumOfFreeSetMinted (address _addr) external view returns (uint8) {
        return mintpassHolders[_addr].minted;
    }
    
    function getNumOfMintsPerAddr(address _addr) external view returns (uint256) {
        return claimedTokenPerWallet[_addr];
    }
    
    // INTERNAL 
    
    function mulScale(
        uint256 x,
        uint256 y,
        uint128 scale
    ) internal pure returns (uint256) {
        uint256 a = x / scale;
        uint256 b = x % scale;
        uint256 c = y / scale;
        uint256 d = y % scale;

        return a * c * scale + a * d + b * c + (b * d) / scale;
    }
}