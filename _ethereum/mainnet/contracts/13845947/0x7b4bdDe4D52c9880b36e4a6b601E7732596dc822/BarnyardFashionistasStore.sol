// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


//import "./draft-EIP712.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

//import "./SignedMinting.sol";

interface NftContract {
    function mint(address) external;
    function balanceOf(address) external view returns (uint256);
}

contract BarnyardFashionistasStore is ReentrancyGuard, Ownable {
//contract BarnyardFashionistasStore is EIP712, SignedMinting, Ownable {
    NftContract public bfNft =
        NftContract(0xBAB7dF6D042F4b83b62070b670Da929b62eD22d8);
    
    address private constant core1Address =
        0x3002E0E7Db1FB99072516033b8dc2BE9897178bA;
    uint256 private constant core1Shares = 84650;

    address private constant core2Address =
        0x452d40db156034223e8865F93d6a532aE62c4A99; 
    uint256 private constant core2Shares = 5000;

    address private constant core3Address =
        0xEbCEe6204eeEEf21e406C0A75734E70f342914e0; 
    uint256 private constant core3Shares = 5000;

    address private constant core4Address =
        0xCa93378a4d2c9217A1f6C2D9aB50B791a4043A87; 
    uint256 private constant core4Shares = 3000;

    address private constant core5Address =
        0xa808208Bb50e2395c63ce3fd41990d2E009E3053; 
    uint256 private constant core5Shares = 750;

    address private constant core6Address =
        0x1996FabEC51878e3Ff99cd07c6CaC9Ac668A22fD; 
    uint256 private constant core6Shares = 600;

    address private constant core7Address =
        0x30734A0adeCa7e07c3C960587d6502fC5EA0f8df; 
    uint256 private constant core7Shares = 500;
    
    address private constant core8Address =
        0x74E101B1E67Cd303A3ec896421ceCf894891ac25; 
    uint256 private constant core8Shares = 500;

    

    uint256 private constant baseMod = 100000;

    /**
        Numbers for Barnyard Fashionistas NftContract
     */
    // uint256 public constant maxFashionistas = 9999;
    uint256 public maxFashionistas = 9999;

    //whitelist and mints
    mapping(address => uint256) private whitelist;    
    mapping(address => uint256) private bonusMintAmount;

    mapping(address => uint256) private oglist;
    mapping(address => uint256) public mintedFashionistasOf;

    /**
        Team allocated Fashionistas
     */
    // Fashionistas which is minted by the owner
    uint256 public preMintedFashionistas = 0;
    // MAX Fashionistas which owner can mint
    uint256 public constant maxPreMintFashionistas = 300;


    //    Mint counts during presale
    uint256 public newlyMintedFashionistasPresale = 0;
    
    //Tracking Sales After Presale
    uint256 public mintedFashionistasAfterPresale = 0;

    uint256 public mintedFashionistasBonus = 0;
    uint256 public mintedOgClaim = 0;

    /**
        Pricing & sales
     */
    uint256 public price = 0.044 ether;
    uint256 public maxMintPerTx = 6;

    uint256 public whitelistMints = 4;

    uint256 public maxMintBonusTx = 2;
    uint256 public maxMintBonus = 1;
    uint256 public bonusMintsTotal = 500;
    uint256 public bonusMintsPresale = 200;

    
    //    Security

  


    uint256 public mintedFashionistas = 227;


    event SetFashionistasNftContract(address bfNft);

    event MintWithWhitelist(address account, uint256 amount, uint256 changes);
    event SetRemainingFashionistas(uint256 remainingFashionistas);

    event mintFashionistas(address account, uint256 amount);
    event Withdraw(address to);


    bool public presaleOn = false;
    bool public mainSaleOn = false;
    bool public bonusSaleOn = false;

    // constructor(
    //     address signer
    // ) 
    // SignedMinting(signer)
    // ReentrancyGuard() 
    // {
    // }

    constructor(
    ) 
    ReentrancyGuard() 
    {
    }

    modifier mainSaleOpened() {
        require( mainSaleOn, "Store is not opened" );

        _;
    }

    modifier presaleOpened() {
        require(presaleOn, "Store is not opened for Presale");

        _;
    }

    modifier bonussaleOpened() {
        require(bonusSaleOn, "Store is not opened for Presale");

        _;
    }

    modifier onlyOwnerOrTeam() {
        require(
            core1Address == msg.sender || core2Address == msg.sender || core4Address == msg.sender || owner() == msg.sender,
            "caller is neither Team Wallet nor Owner"
        );
        _;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setMaxBonusTx(uint256 _newtx) external onlyOwner {
        maxMintBonusTx = _newtx;
    }

    function setMaxBonus(uint256 _newbonus) external onlyOwner {
        maxMintBonus = _newbonus;
    }

    function togglePresale() external onlyOwner {
        presaleOn = !presaleOn;
    }

    function toggleMainSale() external onlyOwner {
        mainSaleOn = !mainSaleOn;
    }
    
    function toggleBonusSale() external onlyOwner {
        bonusSaleOn = !bonusSaleOn;
    }

    function presaleBalance( address checkAddr ) public view returns(uint256) {
        return whitelist[checkAddr];
    }

    // function setMintingSigner(address _signer)
    //     public
    //     onlyOwner
    // {
    //     _setMintingSigner(_signer);
    // }


    function setFashionistasNftContract(NftContract _bfNft) external onlyOwner {
        bfNft = _bfNft;
        emit SetFashionistasNftContract(address(_bfNft));
    }


    // Do not update newlyMintedFashionistas to prevent withdrawal
    // This needs to become the owner Free mint function. Ditch the time restrictions?
    function preMintFashionistas(address[] memory recipients) external onlyOwner {

        uint256 totalRecipients = recipients.length;

        require(
            totalRecipients > 0,
            "Number of recipients must be greater than 0"
        );
        require(
            preMintedFashionistas + totalRecipients <= maxPreMintFashionistas,
            "Exceeds max pre-mint Fashionistas"
        );

        require(
            mintedFashionistas + totalRecipients < maxFashionistas,
            "Exceeds max Fashionistas"
        );

        for (uint256 i = 0; i < totalRecipients; i++) {
            address to = recipients[i];
            require(to != address(0), "receiver can not be empty address");
            bfNft.mint(to);
        }

        preMintedFashionistas += totalRecipients;
        mintedFashionistas += totalRecipients;
    }




    // adds to whitelist with specified amounts
    function addToOGlistAmounts(address[] memory _listToAdd, uint256[] memory _amountPerAddress) public onlyOwner {
        uint256 totalAddresses = _listToAdd.length;
        uint256 totalAmounts = _amountPerAddress.length;

        require(totalAddresses == totalAmounts, "Item amounts differ");

        for (uint256 i = 0; i < totalAddresses; i++) {
          oglist[_listToAdd[i]] = _amountPerAddress[i];
        }
    }


    function ogClaim() public payable presaleOpened
        nonReentrant
    {
        
        uint256 _count = oglist[msg.sender];
        require(mintedFashionistas + _count <= maxFashionistas, "Max limit");

        uint256 _balance = bfNft.balanceOf(msg.sender);

        if ( _balance < _count){
            _count = _balance;
        }

        for (uint256 i = 0; i < _count; i++) {
          bfNft.mint(msg.sender);
        }

        mintedOgClaim += _count;
        mintedFashionistas += _count;

        whitelist[msg.sender] = whitelist[msg.sender] - _count;
    }


    // adds to claim list with specified amounts
    function addToWhitelist(address[] memory _listToAdd) public onlyOwner {
        uint256 totalAddresses = _listToAdd.length;
    
        for (uint256 i = 0; i < totalAddresses; i++) {
          whitelist[_listToAdd[i]] = whitelistMints;
        }
    }


    function mintPresale( uint256 _count) public payable presaleOpened
        nonReentrant
    {
        require(_count <= whitelist[msg.sender], "Over Max whitelist"  );
        
        require(mintedFashionistas + _count <= maxFashionistas, "Max limit");
        require(msg.value >= (_count * price ), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
          bfNft.mint(msg.sender);
        }

        newlyMintedFashionistasPresale += _count;
        mintedFashionistas += _count;

        whitelist[msg.sender] = whitelist[msg.sender] - _count;
    }

    

    function bonusMint( uint256 _count) public payable bonussaleOpened
        nonReentrant
    {
        require(presaleOn || mainSaleOn, "a sale must be on");
        require(_count <= maxMintBonusTx, "Over MaxTx bonus"  );
        require(mintedFashionistasBonus + _count < bonusMintsTotal, "less bonus remaining");
        require(bonusMintAmount[msg.sender] + _count <= maxMintBonus);

        if (presaleOn) {
            require(mintedFashionistasBonus <= bonusMintsPresale, "bonus presale done");

            uint256 fashionistaAmount = bfNft.balanceOf(msg.sender);
            require(fashionistaAmount > 0, "Fashionista Required");    
        }

        require(mintedFashionistas + _count <= maxFashionistas, "Max limit");
        
 
        for (uint256 i = 0; i < _count; i++) {
          bfNft.mint(msg.sender);
        }

        bonusMintAmount[msg.sender] += _count;
        mintedFashionistasBonus += _count;
        mintedFashionistas += _count;

    }



    function mintMainSale(uint256 _amount) external payable mainSaleOpened {
   
        require(mintedFashionistas + _amount -1 < maxFashionistas, "exceeds max mint");

        uint256 totalPrice = price * _amount;
        require(totalPrice <= msg.value, "Not enough money");

        require(_amount - 1 < maxMintPerTx, "exceed max transaction");

        for (uint256 i = 0; i < _amount; i += 1) {
            bfNft.mint(msg.sender);
        }

        mintedFashionistasAfterPresale += _amount;
        mintedFashionistas += _amount;

        emit mintFashionistas(msg.sender, _amount);
    }



    function withdrawCore() external onlyOwnerOrTeam {
        uint256 balance = address(this).balance;
        require(balance > 0);

        _splitAll(balance);
    }

    //  **** ASK HOW MANY CAN DO SAFE
    function _splitAll(uint256 _amount) private {
        uint256 singleShare = _amount / baseMod;
        _withdraw(core1Address, singleShare * core1Shares);
        _withdraw(core2Address, singleShare * core2Shares);
        _withdraw(core3Address, singleShare * core3Shares);
        _withdraw(core4Address, singleShare * core4Shares);
        _withdraw(core5Address, singleShare * core5Shares);
        _withdraw(core6Address, singleShare * core6Shares);
        _withdraw(core7Address, singleShare * core7Shares);
        _withdraw(core8Address, singleShare * core8Shares);
    }

    function withdrawBU() external onlyOwnerOrTeam {
        uint256 balance = address(this).balance;
        require(balance > 0);

        _withdraw(core1Address, balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        payable(_address).transfer(_amount);
    }    

}
