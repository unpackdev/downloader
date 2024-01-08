// SPDX-License-Identifier: MIT
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
// ▄███▄      ▄   ▄█▄     ▄  █ ██      ▄     ▄▄▄▄▀ ▄███▄   ██▄       ▄███▄   █       ▄   ▄███▄     ▄▄▄▄▄
// █▀   ▀      █  █▀ ▀▄  █   █ █ █      █ ▀▀▀ █    █▀   ▀  █  █      █▀   ▀  █        █  █▀   ▀   █     ▀▄
// ██▄▄    ██   █ █   ▀  ██▀▀█ █▄▄█ ██   █    █    ██▄▄    █   █     ██▄▄    █   █     █ ██▄▄   ▄  ▀▀▀▀▄
// █▄   ▄▀ █ █  █ █▄  ▄▀ █   █ █  █ █ █  █   █     █▄   ▄▀ █  █      █▄   ▄▀ ███▄ █    █ █▄   ▄▀ ▀▄▄▄▄▀
// ▀███▀   █  █ █ ▀███▀     █     █ █  █ █  ▀      ▀███▀   ███▀      ▀███▀       ▀ █  █  ▀███▀
//         █   ██          ▀     █  █   ██                                          █▐
//                              ▀                                                   ▐
///////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity 0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract EnchantedElves is ERC721Enumerable, Ownable {
    using Strings for uint256;
    // values initialized in constructor
    string private _contractURI;
    string public _tokenBaseURI;
    string public _filenameExtension = '.json';
    uint public immutable allocGift;
    uint public immutable allocPresale;
    uint public immutable allocMax;
    uint public immutable pricePresale;
    uint public immutable pricePublicsale;
    uint public immutable maxPerMint;
    uint public immutable startIndex;
    uint public giftedAmount;
    bool private _guard;

    address payable private beneficiary_1;
    address payable private beneficiary_2;
    address payable private beneficiary_3;
    address payable private communityWallet;

    uint private immutable p_beneficiary_1;
    uint private immutable p_beneficiary_2;
    uint private immutable p_beneficiary_3;

    ///////////////////////////////
    uint8 public stateOfSale;
    // 0 = default ( no minting allowed )
    // 1 = presale
    // 2 = publicsale
    //////////////////////////

    bool public metadataIsLocked;

    constructor() ERC721("EnchantedElves", "ELVES") {
      allocGift = 20; // giveaways , rewards etc
      allocPresale = 1000;
      allocMax = 9823; // gift + public + presale
      pricePublicsale = 0.07 ether;
      pricePresale = 0.06 ether;
      maxPerMint = 9;

      startIndex = 1; // the ID of the first nft, usually either 0 or 1
      

      beneficiary_1 = payable(0xbaF153A8AfF8352cB6539CF9168255442Def0a02);
      beneficiary_2 = payable(0x0283Ea7a9E1ea19c8De09674635A5e3732987Ab7);
      beneficiary_3 = payable(0x950e6C77e394e9EBEceB6e65A08b9FaC5E5636AE);
      communityWallet = payable(0xF616F94815ddC8533120a88a01E21CBffEea11E4); // multisig - gnosis safe

      p_beneficiary_1 = 32;
      p_beneficiary_2 = 28;
      p_beneficiary_3 = 15;
    }

    modifier onlyWhitelisted(uint8 _v, bytes32 _r, bytes32 _s) {
      require(verifySignature(msg.sender,_v,_r,_s),"Signature verification failed");
      _;
    }

    function verifySignature(address _addr,uint8 _v, bytes32 _r, bytes32 _s) public view returns(bool) {
      bytes32 _hash = keccak256(
        abi.encodePacked(this,_addr)
      );
      return owner() == ecrecover(
        keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",_hash)),
        _v,_r,_s
      );
    }



    function mintPublicsale( uint amount) external payable {
        uint extra = 0;
        if (amount == 9) {
          // Such deal much wow
          extra = 1;
        }

        require(stateOfSale==2, "Publicsale has not started yet");
        require(totalSupply() + amount + extra <= allocMax - allocGift, "Exceeding Publicsale limit");
        require(amount <= maxPerMint, "Minting more than allowed in 1 transaction");
        require(amount > 0,"Cant mint 0");
        require(pricePublicsale * amount == msg.value, "Wrong msg.value");


        for(uint i = 0; i < amount + extra; i++) {
            _safeMint(msg.sender, totalSupply() + startIndex);
        }
    }

    function mintPresale( uint amount, uint8 _v, bytes32 _r, bytes32 _s)
        external payable onlyWhitelisted(_v,_r,_s)
    {
        uint extra = 0;
        if (amount == 9) {
          // Such deal much wow
          extra = 1;
        }

        require(stateOfSale==1, "Presale has not started yet or has ended");
        require(totalSupply() + amount + extra <= allocPresale, "Exceeding total presale limit");
        require(amount <= maxPerMint, "Minting more than allowed in one transaction | Presale");
        require(amount > 0,"Cant mint 0");
        require(pricePresale * amount == msg.value, "Wrong msg.value");

        for(uint i = 0; i < amount + extra; i++) {
            _safeMint(msg.sender, totalSupply() + startIndex);
        }
    }

    modifier notLocked {
        require(!metadataIsLocked, "Contract metadata methods are locked");
        _;
    }




    function giftToMany(address[] calldata receivers) external onlyOwner {
        require(stateOfSale==2,"Can only gift on public sale");
        require(receivers.length > 0,"Needs to have atleast 1 recipient");
        require(giftedAmount + receivers.length <= allocGift, "Exceeding max allowed gifts");

        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], totalSupply() + startIndex);
        }
        giftedAmount+=receivers.length;
    }

    function gift(address receiver) external onlyOwner {
        require(stateOfSale==2,"Can only gift on public sale");
        require(giftedAmount < allocGift, "Maximum number of gifts have already been given away");
        giftedAmount++;
        _safeMint(receiver, totalSupply() + startIndex);
    }


    function withdrawFunds() external {
        require(_guard==false,"Nice try!");
        _guard=true;

        uint amount_1 = address(this).balance * p_beneficiary_1 / 100;
        uint amount_2 = address(this).balance * p_beneficiary_2 / 100;
        uint amount_3 = address(this).balance * p_beneficiary_3 / 100;

        beneficiary_1.transfer(amount_1);
        beneficiary_2.transfer(amount_2);
        beneficiary_3.transfer(amount_3);
        communityWallet.transfer(address(this).balance);

        _guard=false;
    }


    // locks baseURI , meaning metadata base link is frozen
    function lockMetadata() external onlyOwner {
        require(metadataIsLocked == false,"Metadata is already locked");
        metadataIsLocked = true;
    }


    function startPresale() external onlyOwner {
      require(stateOfSale==0,"Presale has already been started");
      stateOfSale++;
    }

    function startPublicsale() external onlyOwner {
      require(stateOfSale==1,"Current mode must be presale");
      stateOfSale++;
    }


    function setContractURI(string calldata URI) external onlyOwner notLocked {
        _contractURI = URI;
    }

    function setBaseURI(string calldata URI) external onlyOwner notLocked {
        _tokenBaseURI = URI;
    }

    function setFilenameExtension(string calldata extension) external onlyOwner notLocked {
        _filenameExtension = extension;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");

        return string(abi.encodePacked(_tokenBaseURI, "/" , tokenId.toString() , _filenameExtension));
    }

    function update_beneficiary_1(address new_beneficiary_1) external {
      require(msg.sender == address(beneficiary_1), "Unauthorized");
      beneficiary_1 = payable(new_beneficiary_1);
    }

    function update_beneficiary_2(address new_beneficiary_2) external {
      require(msg.sender == address(beneficiary_2), "Unauthorized");
      beneficiary_2 = payable(new_beneficiary_2);
    }

    function update_beneficiary_3(address new_beneficiary_3) external {
      require(msg.sender == address(beneficiary_3), "Unauthorized");
      beneficiary_3 = payable(new_beneficiary_3);
    }

    function update_communityWallet(address new_communityWallet) external {
      require(msg.sender == address(communityWallet), "Unauthorized");
      communityWallet = payable(new_communityWallet);
    }
}
