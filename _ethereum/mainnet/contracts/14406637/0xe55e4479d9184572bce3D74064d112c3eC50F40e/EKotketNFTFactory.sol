// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;


import "./EKotketNFTBase.sol";
import "./EKotketNFTPurchaseBase.sol";
import "./EKotketNFTInterface.sol";
import "./EKotketTokenInterface.sol";
import "./ReentrancyGuard.sol";

contract EKotketNFTFactory is EKotketNFTPurchaseBase, EKotketNFTBase, ReentrancyGuard {
    struct KotketPrice {
        uint uKotketToken;
        uint eWei;
    }

    mapping (KOTKET_GENES => KotketPrice) private kotketPriceMap;

    mapping (KOTKET_GENES => uint256) public bredAmountAllowanceMap;

    mapping (address => bool) public activeRefMap;
    mapping (address => address[]) public childRefMap;
    mapping (address => address) public parentRefMap;



    event NFTBorn(address indexed beneficiary, address indexed referral, uint256 weiValue, uint256 uKotketValue, KOTKET_GENES gene, uint256 id);
    event NFTRateChanged(KOTKET_GENES indexed gene, uint256 uKotketTokenRate, uint256 weiRate, address setter);
    event NFTBredAmountAllowanceChanged(KOTKET_GENES indexed gene, uint256 _amount);
    constructor(address _governanceAdress) EKotketNFTPurchaseBase(_governanceAdress) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        bredAmountAllowanceMap[KOTKET_GENES.KITI] = 0;
        bredAmountAllowanceMap[KOTKET_GENES.RED] = 5000;
        bredAmountAllowanceMap[KOTKET_GENES.BLUE] = 2500;
        bredAmountAllowanceMap[KOTKET_GENES.LUCI] = 1250;
        bredAmountAllowanceMap[KOTKET_GENES.TOM] = 625;
        bredAmountAllowanceMap[KOTKET_GENES.KOTKET] = 312;
        bredAmountAllowanceMap[KOTKET_GENES.KING] = 166;
    }

    function updateBredAmountAllowance(uint8 _gene, uint256 _amount) public onlyAdminPermission{
        require(_gene <= uint8(KOTKET_GENES.KING), "Invalid Gene");
        KOTKET_GENES gene = KOTKET_GENES(_gene);
        bredAmountAllowanceMap[gene] = _amount;

        emit NFTBredAmountAllowanceChanged(gene, _amount);
    }

    function updatePrice(uint8 _gene, uint256 _uKotketToken, uint256 _eWei) public onlyAdminPermission{
        require(_gene <= uint8(KOTKET_GENES.KING), "Invalid Gene");
        KOTKET_GENES gene = KOTKET_GENES(_gene);
        kotketPriceMap[gene].uKotketToken = _uKotketToken;
        kotketPriceMap[gene].eWei = _eWei;     
        emit NFTRateChanged(gene, _uKotketToken, _eWei, _msgSender());   
    }

    function checkKotketPrice(uint8 _gene) public view returns(uint uKotketToken, uint eWei){
        require(_gene <= uint8(KOTKET_GENES.KING), "Invalid Gene");
        KOTKET_GENES gene = KOTKET_GENES(_gene);

        return (kotketPriceMap[gene].uKotketToken, kotketPriceMap[gene].eWei);
    }

    function setActiveRefSatus(address referrer, bool status) public onlyAdminPermission{
        require(referrer != address(0), "Invalid Referral Address");
        activeRefMap[referrer] = status;
    }

    function handleReferral(address _referrer) internal{
        if (_referrer!= address(0)){        
            require(activeRefMap[_referrer], "Inactived Referral Address");
            require(_referrer != _msgSender(), "Cannot Referral Yourself");

            require(parentRefMap[_msgSender()] == address(0) || parentRefMap[_msgSender()] == _referrer, "Invalid Referral Address");

            if (parentRefMap[_msgSender()] == address(0)){
                parentRefMap[_msgSender()] = _referrer;
                childRefMap[_referrer].push(_msgSender());
            }
        }else{
            require(parentRefMap[_msgSender()] != address(0), "Not allowed empty referrer");
        }

        if (!activeRefMap[_msgSender()]){
            activeRefMap[_msgSender()] = true;
        }
    }

    function bred(uint256 _tokenId,
        uint8 _gene, 
        string memory _name, 
        string memory _metadataURI,
        uint256 weiValue,
        uint256 uKotketValue) internal{
        
        KOTKET_GENES gene = KOTKET_GENES(_gene);        
        EKotketNFTInterface kotketNFT = EKotketNFTInterface(governance.kotketNFTAddress());
        kotketNFT.kotketBred(_msgSender(), _tokenId, _gene, _name, _metadataURI);    
        bredAmountAllowanceMap[gene] -= 1;

        emit NFTBorn(_msgSender(), parentRefMap[_msgSender()], weiValue, uKotketValue, gene, _tokenId);
        emit NFTBredAmountAllowanceChanged(gene, bredAmountAllowanceMap[gene]);
    }

    function bredNFTWithWei(uint256 _tokenId,
        address _referrer,
        uint8 _gene, 
        string memory _name, 
        string memory _metadataURI) public nonReentrant payable {
        
        require(allowedWeiPurchase, "Not allowed wei purchase");
        
        require(_gene <= uint8(KOTKET_GENES.KING), "Invalid Gene");
        KOTKET_GENES gene = KOTKET_GENES(_gene);

        require(bredAmountAllowanceMap[gene] > 0, "Not allow to bred more NFT of this gene");

        uint256 weiAmount = msg.value;
        require(weiAmount >= kotketPriceMap[gene].eWei, "insufficient wei amount");

        handleReferral(_referrer);

        _forwardWeiFunds();

        bred(_tokenId, _gene, _name, _metadataURI, weiAmount, 0);
    }

    function _forwardWeiFunds() internal virtual{
        address payable kotketWallet = payable(governance.kotketWallet());
        kotketWallet.transfer(msg.value);
    }

    function bredNFTWithKotketToken(uint256 _tokenId,
        address _referral,
        uint8 _gene, 
        string memory _name, 
        string memory _metadataURI) public{        

        require(allowedKotketTokenPurchase, "Not allowed kotket token purchase");

        require(_gene <= uint8(KOTKET_GENES.KING), "Invalid Gene");
        KOTKET_GENES gene = KOTKET_GENES(_gene);

        require(bredAmountAllowanceMap[gene] > 0, "Not allow to bred more NFT of this gene");

        uint256 price = kotketPriceMap[gene].uKotketToken;

        EKotketTokenInterface kotketToken = EKotketTokenInterface(governance.kotketTokenAddress());
        require(kotketToken.balanceOf(_msgSender()) >= price, "Insufficient Kotket Token Balance!");

        uint256 tokenAllowance = kotketToken.allowance(_msgSender(), address(this));
        require(tokenAllowance >= price, "Not Allow Enough Kotket Token To Bred NFT");

        handleReferral(_referral);
       
        kotketToken.transferFrom(_msgSender(), governance.kotketWallet(), price);

        bred(_tokenId, _gene, _name, _metadataURI, 0, price);
    }

    receive() external payable {}
}