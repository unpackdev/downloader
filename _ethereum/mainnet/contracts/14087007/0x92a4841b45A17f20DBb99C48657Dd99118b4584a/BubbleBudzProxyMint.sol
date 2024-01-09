//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Open0x Ownable (by 0xInuarashi)
abstract contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed oldOwner_, address indexed newOwner_);
    constructor() { owner = msg.sender; }
    modifier onlyOwner {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function _transferOwnership(address newOwner_) internal virtual {
        address _oldOwner = owner;
        owner = newOwner_;
        emit OwnershipTransferred(_oldOwner, newOwner_);    
    }
    function transferOwnership(address newOwner_) public virtual onlyOwner {
        require(newOwner_ != address(0x0), "Ownable: new owner is the zero address!");
        _transferOwnership(newOwner_);
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0x0));
    }
}

abstract contract PayableGovernance is Ownable {
    // Receivable Fallback
    event Received(address from, uint amount);
    receive() external payable { emit Received(msg.sender, msg.value); }

    // Payable Governance
    mapping(address => bool) internal shareholderToUnlockGovernance;

    address internal Shareholder_1 = 0x1D628369DD259660482bf6c14Cb558F8d69a8242; // Chief
    address internal Shareholder_2 = 0x1eD3D146cb5945e1C894A70013Ed83F95693EA22; // 0xInuarashi

    uint internal Shareholder_1_Share = 80; // Chief
    uint internal Shareholder_2_Share = 20; // 0xInuarashi

    function withdrawEther() public onlyOwner {
        uint _totalETH = address(this).balance; // balance of contract

        uint _Shareholder_1_ETH = ((_totalETH * Shareholder_1_Share) / 100); 
        uint _Shareholder_2_ETH = ((_totalETH * Shareholder_2_Share) / 100); 

        payable(Shareholder_1).transfer(_Shareholder_1_ETH);
        payable(Shareholder_2).transfer(_Shareholder_2_ETH);
    }
    function viewWithdrawEtherAmounts() public view onlyOwner returns (uint[] memory) {
        uint _totalETH = address(this).balance;
        uint[] memory _ethToSendArray = new uint[](4);

        uint _Shareholder_1_ETH = ((_totalETH * Shareholder_1_Share) / 100); 
        uint _Shareholder_2_ETH = ((_totalETH * Shareholder_2_Share) / 100); 

        _ethToSendArray[0] = _Shareholder_1_ETH;
        _ethToSendArray[1] = _Shareholder_2_ETH;
        _ethToSendArray[2] = _totalETH;
        _ethToSendArray[3] = _Shareholder_1_ETH + _Shareholder_2_ETH; 

        return _ethToSendArray;
    }

    // Payable Governance Emergency Functions
    modifier onlyShareholder {
        require(msg.sender == Shareholder_1 || msg.sender == Shareholder_2, "You are not a shareholder!");
        _;
    }
    modifier emergencyOnly {
        require(shareholderToUnlockGovernance[Shareholder_1] && shareholderToUnlockGovernance[Shareholder_2], "Emergency Functions have not been unlocked!");
        _;
    }

    function unlockEmergencyFunctionsAsShareholder() public onlyShareholder {
        shareholderToUnlockGovernance[msg.sender] = true;
    }
    function emergencyWithdrawEther() public onlyOwner emergencyOnly {
        payable(msg.sender).transfer(address(this).balance);
    }

    function checkGovernanceStatus(address address_) public view onlyShareholder returns (bool) {  
        return shareholderToUnlockGovernance[address_];
    }
}

interface iBubbleBudz {
    function totalSupply() external view returns (uint256);
    function ownerMintMany(address to_, uint256 amount_) external;
    function transferOwnership(address newOwner_) external;
    function ownerOf(uint256 tokenId_) external view returns (address);
    function normalTokensLimit() external view returns (uint256);
    function normalTokensMinted() external view returns (uint256);
    function addressToWhitelistMints(address address_) external view returns (uint256);
    function addressToPublicMints(address address_) external view returns (uint256);
    function withdrawEther() external;
}

interface iBubblez {
    function balanceOf(address address_) external view returns (uint); // erc20 balance
    function transferFrom(address from_, address to_, uint amount_) external returns (bool); // transferFrom erc20
    function burn(address from_, uint amount_) external; // function to burn tokens
}

contract BubbleBudzProxyMint is Ownable, PayableGovernance {
    // Interfaces
    iBubbleBudz public BB = iBubbleBudz(0xA4c3D7300875d99b5B227917faCf98cC7B08cC53);
    function setBubbleBudz(address address_) external onlyOwner {
        BB = iBubbleBudz(address_);
    }
    iBubblez public Bubblez = iBubblez(0x9bd47f1Cd84c30ADa1CDeC139260b36810c449f9);
    function setBubblez(address address_) external onlyOwner {
        Bubblez = iBubblez(address_);
    }

    // General NFT Variables
    uint256 public mintPrice = 0.045 ether;
    uint256 public maxMintsPerTx = 50;

    uint256 public bubblezPrice = 1000 ether;

    function setMintPrice(uint256 mintPrice_) external onlyOwner {
        mintPrice = mintPrice_; 
    }
    function setMaxMintsPerTx(uint256 maxMintsPerTx_) external onlyOwner {
        maxMintsPerTx = maxMintsPerTx_;
    }
    function setBubblezPrice(uint256 bubblezPrice_) external onlyOwner {
        bubblezPrice = bubblezPrice_;
    }

    // Access
    function transferOwnershipOfBB(address newOwner_) external onlyOwner {
        BB.transferOwnership(newOwner_);
    }
    // Just In Case
    function BBWithdrawEther() external onlyOwner {
        BB.withdrawEther();
    }

    // Modifiers
    modifier onlySender { require(msg.sender == tx.origin, "No contracts"); _; }

    // Internal Mint
    function _mint(address to_, uint256 amount_) internal {
        BB.ownerMintMany(to_, amount_);
    }

    // Owner Mint 
    function ownerMint(address to_, uint256 amount_) public onlyOwner {
        _mint(to_, amount_);
    }

    // Claim Proxy Logic (Free Claim)
    bool public publicClaimEnabled = true; // Default to true
    modifier publicClaiming { require(publicClaimEnabled, "Claim not started!"); _; }
    function setPublicClaiming(bool bool_) external onlyOwner { 
        publicClaimEnabled = bool_;
    }

    uint256 publicClaimUntil = 5000; // It ends at 5000
    uint256 maxClaimPerAddress = 4; // Only 4 per address
    function setPublicClaimUntil(uint256 tokenId_) external onlyOwner {
        publicClaimUntil = tokenId_;
    }
    function setMaxClaimPerAddress(uint256 amount_) external onlyOwner {
        maxClaimPerAddress = amount_;
    }

    mapping(address => uint256) public addressToClaimedBB;

    function claim(uint256 amount_) public onlySender publicClaiming {
        require(publicClaimUntil >= BB.totalSupply() + amount_, "No more claims!");
        require(maxMintsPerTx >= amount_, "Over max mints per tx!");
        require(maxClaimPerAddress >= addressToClaimedBB[msg.sender] + amount_,
            "Over max claims for your address!");

        addressToClaimedBB[msg.sender] += amount_;

        // Mint
        _mint(msg.sender, amount_);
    }

    // Mint Proxy Logic (Public Mint)
    bool public publicMintEnabled = true; // Default to true
    modifier publicMinting { require(publicMintEnabled, "PM not started!"); _; }
    function setPublicMint(bool bool_) external onlyOwner{ publicMintEnabled = bool_; }

    uint256 public publicMintUntil = 5000; // It ends at 5000
    function setPublicMintUntil(uint256 tokenId_) external onlyOwner {
        publicMintUntil = tokenId_;
    }

    function mint(uint256 amount_) public payable onlySender publicMinting {
        require(publicMintUntil >= BB.totalSupply() + amount_, 
            "No more public mints!"); 
        require(maxMintsPerTx >= amount_, "Over max mints per tx!");
        require(msg.value == mintPrice * amount_, "Invalid value sent!");

        // Mint many to msg.sender
        _mint(msg.sender, amount_);
    }

    // Mint Proxy Logic ($BUBBLEZ Mint)
    bool public bubblezMintEnabled = true; // Default to true
    modifier bubblezMinting { require(bubblezMintEnabled, "BBM not started!"); _; }
    function setBubblezMint(bool bool_) external onlyOwner { 
        bubblezMintEnabled = bool_; 
    }   

    uint256 public bubblezMintUntil = 6000; // It ends at 6000
    function setBubblezMintUntil(uint256 tokenId_) external onlyOwner {
        bubblezMintUntil = tokenId_;
    }

    function bubblezMint(uint256 amount_) public onlySender bubblezMinting {
        require(bubblezMintUntil >= BB.totalSupply(), "No more bubblez mints!");
        require(maxMintsPerTx >= amount_, "Over max mints per tx!");

        uint256 _cost = bubblezPrice * amount_;

        require(Bubblez.balanceOf(msg.sender) >= _cost,
            "You don't have enough $BUBBLEZ!");
        
        Bubblez.burn(msg.sender, _cost);
        
        _mint(msg.sender, amount_);
    }
}