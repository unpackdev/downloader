//
//
//
////////////////////////////////////////////////////////////////////////////////////////
// __________        .__                        ___ ___                     .__       //
// \______   \_____  |__| ____   ___________   /   |   \  ____  ______ ____ |  |__    //
//  |       _/\__  \ |  |/    \_/ __ \_  __ \ /    ~    \/  _ \/  ___// ___\|  |  \   //
//  |    |   \ / __ \|  |   |  \  ___/|  | \/ \    Y    (  <_> )___ \\  \___|   Y  \  //
//  |____|_  /(____  /__|___|  /\___  >__|     \___|_  / \____/____  >\___  >___|  /  //
//         \/      \/        \/     \/               \/            \/     \/     \/   //
////////////////////////////////////////////////////////////////////////////////////////
//
//
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155PresetMinterPauser.sol";
import "./MerkleProof.sol";

contract IconsOfNFTMinter is Ownable {

    address public iCONSofNFTAddress = 0x476Ae7237d50E01C84d8f04E7C8021909600A898;

    bytes32 public root = 0x232450d8a4fb5d9e42138c429c6be5b0a6154662cb284556acb6c8b6f26c9545;

    uint256 public publicPrice = 0.01 ether;

    bool public isWhitelistMintEnabled = true;
    bool public isPublicMintEnabled = true;

    mapping(address => uint256) public claimedNFTs;

    function setRoot(bytes32 newroot) public onlyOwner {root = newroot;}


    function setIsPublicMintEnabled(bool isEnabled) public onlyOwner {
        isPublicMintEnabled = isEnabled;
    }

    function setIsWhitelistMintEnabled(bool isEnabled) public onlyOwner {
        isWhitelistMintEnabled = isEnabled;
    }

    function getPublicPrice() public view returns (uint256) {
        return publicPrice;
    }

    function setPublicPrice(uint256 _price)
        public
        onlyOwner
    {
        publicPrice = _price;
    }

    function setIconsOfNFTAddress(address _address)  public onlyOwner {
        iCONSofNFTAddress = _address;
    }
    
    function airdrop(
        address[] memory to,
        uint256[] memory id,        
        uint256[] memory amount
    ) onlyOwner public {
        require(to.length == id.length && to.length == amount.length, "Length mismatch");
        ERC1155PresetMinterPauser token = ERC1155PresetMinterPauser(iCONSofNFTAddress);
        for (uint256 i = 0; i < to.length; i++)
            token.mint(to[i], id[i], amount[i], "");
    }

    function mintWhitelist(bytes32[] calldata proof) public {
        require(isWhitelistMintEnabled, "Mint not enabled");
        require(MerkleProof.verify(proof, root, keccak256(abi.encodePacked(msg.sender))), "Invalid merkle proof");
        require(claimedNFTs[msg.sender] < 1, "Wallet already claimed");
        
        ERC1155PresetMinterPauser token = ERC1155PresetMinterPauser(iCONSofNFTAddress);
        token.mint(msg.sender, 1, 1, "");
        
        claimedNFTs[msg.sender] = 1; 
    }

    function mintPublic(uint256 amount) public payable {
        require(isPublicMintEnabled, "Mint not enabled");
        require(msg.value >= publicPrice * amount, "Not enough eth");
        require(amount > 0, "Amount must be greater than 0");

        ERC1155PresetMinterPauser token = ERC1155PresetMinterPauser(iCONSofNFTAddress);
        token.mint(msg.sender, 1, amount, "");
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
