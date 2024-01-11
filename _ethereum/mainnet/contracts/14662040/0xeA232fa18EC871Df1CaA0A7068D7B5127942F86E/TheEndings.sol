// SPDX-License-Identifier: MIT

/**
*   @title The Endings
*   @notice The Endings by Caitlin Cronenberg, an editioned, interactive photography book
*   @author Transient Labs
*/

/*
  _______ _            ______           _ _                 
 |__   __| |          |  ____|         | (_)                
    | |  | |__   ___  | |__   _ __   __| |_ _ __   __ _ ___ 
    | |  | '_ \ / _ \ |  __| | '_ \ / _` | | '_ \ / _` / __|
    | |  | | | |  __/ | |____| | | | (_| | | | | | (_| \__ \
    |_|  |_| |_|\___| |______|_| |_|\__,_|_|_| |_|\__, |___/
                                                   __/ |    
                                                  |___/     
   ___                            __  ___         ______                  _          __    __        __     
  / _ \___ _    _____ _______ ___/ / / _ )__ __  /_  __/______ ____  ___ (_)__ ___  / /_  / /  ___ _/ /  ___
 / ___/ _ \ |/|/ / -_) __/ -_) _  / / _  / // /   / / / __/ _ `/ _ \(_-</ / -_) _ \/ __/ / /__/ _ `/ _ \(_-<
/_/   \___/__,__/\__/_/  \__/\_,_/ /____/\_, /   /_/ /_/  \_,_/_//_/___/_/\__/_//_/\__/ /____/\_,_/_.__/___/
                                        /___/                                                               
*/

pragma solidity ^0.8.0;

import "./ERC721TLCore.sol";

contract TheEndings is ERC721TLCore {

    uint16[] internal availableTokenIds;

    constructor(address royaltyRecp, uint256 royaltyPerc, 
        uint256 price, bytes32 merkleRoot, 
        address admin, address payout)
        ERC721TLCore("The Endings", "END", royaltyRecp, royaltyPerc, 
        price, 500, merkleRoot, admin, payout) {
            uint16[500] memory tokenIds;
            for (uint16 i = 0; i < 500; i++) {
                tokenIds[i] = i + 1;
            }
            availableTokenIds = tokenIds;
    }

    /**
    *   @notice function for batch minting to many addresses
    *   @dev requires owner or admin
    *   @dev airdrop not subject to mint allowance constraintss
    *   @param addresses is an array of addresses to mint to
    */
    function airdrop(address[] calldata addresses) external override adminOrOwner {
        revert("disabled");
    }
    
    /**
    *   @notice function for minting to the owner's address
    *   @dev requires owner or admin
    *   @dev not subject to mint allowance constraints
    */
    function ownerMint(uint128 numToMint) external override adminOrOwner {
        require(numToMint == 1, "numToMint must be 1");
        require(availableTokenIds.length > 0, "All pieces have been minted");

        uint256 num = getRandomNum(availableTokenIds.length);
        uint256 id = uint256(availableTokenIds[num]);

        availableTokenIds[num] = availableTokenIds[availableTokenIds.length - 1];
        availableTokenIds.pop();

        _safeMint(owner(), id);
    }

    /**
    *   @notice allowlist mint function
    *   @dev requires mint to be open
    *   @dev requires merkle proof to be valid, if in presale mint
    *   @dev requires mint price to be met
    *   @dev requires that the message sender hasn't already minted more than allowed at the time of the transaction
    *   @param merkleProof is the proof provided by the minting site
    */
    function mint(bytes32[] calldata merkleProof) public payable override {
        require(availableTokenIds.length > 0, "All pieces have been minted");
        require(msg.value >= mintPrice, "Not enough ether");
        require(numMinted[msg.sender] < mintAllowance, "Reached mint limit");
        if (allowlistSaleOpen) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(merkleProof, allowlistMerkleRoot, leaf), "Not on allowlist");
        }
        else if (!publicSaleOpen) {
            revert("Mint not open");
        }
        numMinted[msg.sender]++;
        uint256 num = getRandomNum(availableTokenIds.length);
        uint256 id = uint256(availableTokenIds[num]);

        availableTokenIds[num] = availableTokenIds[availableTokenIds.length - 1];
        availableTokenIds.pop();

        _safeMint(msg.sender, id);
    }

    /**
    *   @notice function to view remaining supply
    */
    function getRemainingSupply() external view override returns (uint256) {
        return availableTokenIds.length;
    }

    /**
    *   @notice function to get psuedo random token id to mint
    *   @param upper is the upper limit to get a number between (exculsive)
    */
    function getRandomNum(uint256 upper) internal view returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.coinbase, block.difficulty, msg.sender)));
        return random % upper;
    }
}