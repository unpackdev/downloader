// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";

contract PrivateCityNFT is ERC721A {
    address public contractOwner;
    address public admin;
    address[] public specialWallets;
    uint256 public pauseAtId = 10000;
    uint256 public currentIndex;
    uint256 public pricePerNFT;
    uint256 public totalAllocatedPercentage = 100; //starts at 10% to accommodate referral
    string public uri;
    bool public mintOpen = false;

    mapping(uint256 => string) private uriByTokenId;
    mapping(address => uint256) public payoutPercentage;

    event Payout(
        address indexed mintingAddress, 
        address indexed payoutAddress, 
        bool indexed isSpecialWaletPayout,
        uint256 timestamp, 
        uint256 mints, 
        uint256 price,
        uint256 referralEarnings
    );

    event NewSpecialWalet(address indexed walletAddress, string name);

    constructor(uint256 _pricePerNFT)
        ERC721A("Millenium Foundation NFT", "MILL")
    {
        pricePerNFT = _pricePerNFT;
        contractOwner = msg.sender;
    }

    //Minting controls
    function openMint(bool _isOpen) public {
        require(msg.sender == admin || msg.sender == contractOwner, "Method can only be called by owner or admin");
        mintOpen = _isOpen;
    }

    function mint(uint256 _quantity, address payable _referral) public payable {
        require(mintOpen);
        require(
            (_currentIndex + _quantity) < pauseAtId + 1,
            "Reached pauseAt Id value"
        );
        require(msg.value == pricePerNFT * _quantity, "Wrong ETH amount sent");

        for (uint256 i = 0; i < _quantity; i++) {
            uriByTokenId[_currentIndex + i] = uri;
        }
        
        if(_referral != 0x0000000000000000000000000000000000000000){
            _referral.transfer(msg.value/10);
            emit Payout(
                msg.sender,
                 _referral,
                false,
                 block.timestamp,
                 _quantity,
                 msg.value,
                msg.value/10
            );
        }

        for(uint i; i< specialWallets.length; i++){
            payable(specialWallets[i]).transfer(msg.value * payoutPercentage[specialWallets[i]]/1000);
            emit Payout(
                msg.sender,
                 specialWallets[i],
                 true,
                 block.timestamp,
                 _quantity,
                 msg.value,
                msg.value * payoutPercentage[specialWallets[i]]/1000
            );
        }
        
        _safeMint(msg.sender, _quantity);
        currentIndex = _currentIndex;
    }

    //Admin edit & withdraw eth functions
    function setPricePerNFT(uint256 _pricePerNFT) public onlyOwnerOrAdmin {
        pricePerNFT = _pricePerNFT;
    }

    function setUri(string memory _uri) public onlyOwnerOrAdmin {
        uri = _uri;
    }

    function setPauseAtId(uint256 _pauseAtId) public onlyOwnerOrAdmin {
        pauseAtId = _pauseAtId;
    }

    function setUriById(uint256 _id, string memory _uri) public onlyOwnerOrAdmin {
        uriByTokenId[_id] = _uri;
    }

    function withdrawEth() public onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        contractOwner = _newOwner;
    }

    function changeAdmin(address _newAdmin) public onlyOwnerOrAdmin {
        admin = _newAdmin;
    }

    function addSpecialWallet(address _specialWallet, uint256 _percentage, string calldata _name) public onlyOwnerOrAdmin {
        require(totalAllocatedPercentage + _percentage <= 1000, "Suggested special wallet percentage too high");
        require(findSpecialWallet(_specialWallet) == -1, "Special wallet has already been added");

        specialWallets.push(_specialWallet);
        payoutPercentage[_specialWallet] = _percentage;
        totalAllocatedPercentage +=  _percentage;
        emit NewSpecialWalet(_specialWallet, _name);    

    }

    function getSpecialWallets() public view returns(address[] memory){
        return specialWallets;
    }

    function removeSpecialWallet(address _specialWallet) public onlyOwnerOrAdmin {
        uint walletIndex = uint(findSpecialWallet(_specialWallet));
        require(specialWallets.length > walletIndex, "Index out of range");

        for(uint i = walletIndex; i < specialWallets.length - 1; i++){
            specialWallets[i] = specialWallets[i+1];
        }
        specialWallets.pop();
        totalAllocatedPercentage -= payoutPercentage[_specialWallet];
        payoutPercentage[_specialWallet] = 0;
    }

    function changeSpecialWalletPercentage(address _specialWallet, uint256 _percentage) public onlyOwnerOrAdmin {
        require(findSpecialWallet(_specialWallet) != -1, "Special wallet has not been added");
        require(totalAllocatedPercentage - payoutPercentage[_specialWallet] + _percentage <= 1000, "Suggested special wallet percentage too high");
        totalAllocatedPercentage = totalAllocatedPercentage - payoutPercentage[_specialWallet] + _percentage;
        payoutPercentage[_specialWallet] = _percentage;
    }

    //Metadata URI functions
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(uriByTokenId[tokenId]).length > 0
                ? uriByTokenId[tokenId]
                : "";
    }

    //Helper functions anf modifiers
    function findSpecialWallet(address _specialWallet) internal view returns(int) {
        int addressIndex = -1;
        for(uint i; i < specialWallets.length; i++){
            if(specialWallets[i] == _specialWallet){
                addressIndex = int(i);
            }
        }
        return addressIndex;
    }
    
    modifier onlyOwner {
      require(msg.sender == contractOwner, "Method can only be called by owner");
      _;
    }

   modifier onlyOwnerOrAdmin {
      require(msg.sender == admin || msg.sender == contractOwner, "Method can only be called by owner or admin");
      _;
   }
}