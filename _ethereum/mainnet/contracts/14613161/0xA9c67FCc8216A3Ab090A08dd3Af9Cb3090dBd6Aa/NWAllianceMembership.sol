// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";


contract NWAllianceMembership is ERC721A, Ownable {
    
    uint16 public maxSupplyPlus1 = 5556;
    uint16 public maxPreSaleSupplyPlus1 = 1001;
    string public baseURI = "ifps://QmUgjxpFiWmyqW8fgRcNLU9pNscBM3bLiFPjmnEobq1ry3/";
    bytes32 public presale = 0x23089356dcbbccd5c278be7a328f75ab39c18537ebf1f44fc74aa9267e137924;
    bool public presaleOnly = true;
    bool public mintPaused = false;
    uint8 public maxMintPerWalletPlus1 = 6;
    uint8 public mintCost = 0; // in 0.01 ETH increments


    constructor() ERC721A("NWAllianceMembership", "NWAC") {    }


    // MINTING

    function mint(uint amt_, address to_) external payable priceMet(amt_) notPaused {
        require (!presaleOnly, "Minting is currently only available for Presale" );
        require ((totalSupply() + amt_) < maxSupplyPlus1, "Total Supply Exceeded");
        require ((balanceOf(msg.sender) + amt_) < maxMintPerWalletPlus1, "This order exceeds maximum Mint Limit per Wallet" );

        if (msg.sender == owner()) {
            _safeMint(to_, amt_);
        }
        else {
            _safeMint(msg.sender, amt_);
        }
        
    }

    function presaleMint(bytes32[] calldata presale_, uint8 amt_) external payable priceMet(amt_) notPaused {
        require (presaleOnly, "Presale minting is closed" );
        require ((totalSupply() + amt_) < maxPreSaleSupplyPlus1, "This order exceeds maximum Pre-Sale Total Supply");
        require ((balanceOf(msg.sender) + amt_) < maxMintPerWalletPlus1, "This order exceeds maximum Pre-Sale Mint Limit per Wallet" );
        require (presale == verifyPresale(presale_, keccak256(abi.encode(msg.sender))), "This wallet is not authorized for Pre-Sale" );

        _safeMint(msg.sender, amt_);

    }


    // PRESALE

    function verifyPresale(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }
    
    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }


    // MODIFIERS

    modifier priceMet (uint amt_) {
        if (mintCost > 0) {
            require ((amt_ * mintCost * 0.01 ether) < msg.value + 1, "Mint price not met" );
        }
        _;
    }

    modifier notPaused {
        require (!mintPaused, "Minting is currently paused" );
        _;
    }


    // CONFIGURATION

    function get_config() external view returns (bool, bool, uint8, uint8, uint16, uint16) {
      return (
        mintPaused,
        presaleOnly,
        mintCost,
        maxMintPerWalletPlus1,
        maxPreSaleSupplyPlus1,
        maxSupplyPlus1
      );
    }

    function set_mintPaused(bool isPaused_) external onlyOwner { mintPaused = isPaused_; }

    function set_presaleOnly(bool ispresale_) external onlyOwner { presaleOnly = ispresale_; }

    function set_maxMintPerWalletPlus1(uint8 maxPlus1_) external onlyOwner { maxMintPerWalletPlus1 = maxPlus1_; }

    function set_mintCost(uint8 cost_) external onlyOwner { mintCost = cost_; }
    
    function set_presale(bytes32 presale_) external onlyOwner { presale = presale_; }

    function set_baseURI(string calldata newBaseURI_) external onlyOwner { baseURI = newBaseURI_; }

    function set_maxPreSaleSupply(uint16 maxPreSaleSupplyPlus1_) external onlyOwner { maxPreSaleSupplyPlus1 = maxPreSaleSupplyPlus1_; }

    function set_maxSupply(uint16 maxSupplyPlus1_) external onlyOwner { maxSupplyPlus1 = maxSupplyPlus1_; }


    // WITHDRAW

    function withdraw() external payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }


    // OVERRIDES
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent NFT");

      return bytes(baseURI).length > 0
          ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"))
          : "";
    }

    function renounceOwnership() public view override onlyOwner {
        revert("This contract needs an owner. Transfer instead.");
    }


}