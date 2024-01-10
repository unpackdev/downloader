// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "./Context.sol";
import "./Ownable.sol";
import "./Address.sol";
//import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
//import "./Base64.sol";
import "./CalladitaToken721.sol";

contract CalladitaCrowdfundingV4 is Context, ReentrancyGuard, Ownable{

    //using SafeMath for uint256;
    using Address for address;
    using Strings for uint256;
    using Strings for uint8;


    /*
     * Event for funding
     * @param sender who send funds     
     * @param amount transfered
     */
    event Funding(address indexed sender, uint256 amount);

    //Balances
    mapping(address => uint256) private userBalance;
    
    //End date
    //uint256 private endDate;

    // Address where funds are collected
    address payable private _wallet;

    // Amount of wei raised
    uint256 private _weiRaised;

    mapping(uint8 => uint256) public tokenTierCounter;
    mapping(uint8 => uint256) private tokenTierMax;
    mapping(uint8 => uint256) private tokenTierUnitCost;

    CalladitaToken721 public _token;

    

    /*
    * @param wallet Address where collected funds will be forwarded to    
    */
    constructor (address payable recipientWallet)
    {
        require(recipientWallet != address(0), "Crowdsale: wallet is the zero address");
        
        _wallet = recipientWallet;

        //End date by default is set 60 days from deploy date
        //endDate = block.timestamp + 60 days;

        tokenTierMax[1] = 2300;
        tokenTierMax[2] = 92;
        tokenTierMax[3] = 15;
        tokenTierMax[4] = 5;

        tokenTierUnitCost[1] = 180000000000000000;
        tokenTierUnitCost[2] = 600000000000000000;
        tokenTierUnitCost[3] = 3000000000000000000;
        tokenTierUnitCost[4] = 6000000000000000000;

        //_token = token;
        _token = new CalladitaToken721();

        _token.transferOwnership (msg.sender);
    }

    receive () external payable {
        _forwardFunds(msg.value);
    }

    function tokenURI(uint8 _tier, uint256 _counter) private pure returns (string memory)
    {
        string memory baseURI = "https://calladita.mypinata.cloud/ipfs/QmSjxSvMPjYtCEZfdVLciHGCySJnVjZZ58hZR4BaTLxAet/";

        return string(abi.encodePacked(baseURI, "tier_",_tier.toString(), "_", _counter.toString(), ".json"));

    }

    //El usuario elige desde el front, que TIER y que cantidad de tokens quiere comprar.
    //La cantidad de ETH que transfiere el usuario se calcula en el front y viene seteado en msg.value.
    //(es el producto de la cantidad de tokens elegido y el precio prefijado del tier).
    function fundCalladita(uint8 _tier, uint256 _tokenAmount) public payable nonReentrant {
        address spender = _msgSender();
        _preValidateFunding(msg.value);
        _preValidateAmount(msg.value, _tier, _tokenAmount);

        // Update user balance
        userBalance[spender] = userBalance[spender] + msg.value;

        // update state
        _weiRaised = _weiRaised + msg.value;

        _forwardFunds(msg.value);
        emit Funding(spender, msg.value);

        for (uint256 i; i < _tokenAmount; i++) {

            string memory _tokenUri = "";
            tokenTierCounter[_tier]++;
            _tokenUri = tokenURI(_tier, tokenTierCounter[_tier]);
            _token.awardNFT(msg.sender, _tokenUri);
        }
    }
  
    function _forwardFunds(uint256 amount) internal {
        (bool success, ) = payable(_wallet).call{value: amount}("");
        require(success, "ForwardFunds: unable to send value");
    }

    //weiAmount: msg.value, _tier: 1,2,3 or 4, _tokenAmount: token quantity
    function _preValidateAmount(uint256 weiAmount, uint8 _tier, uint256 _tokenAmount) internal view {  
        uint256 weiTotal;
        uint256 tokensAvailabe;

        weiTotal = tokenTierUnitCost[_tier] * _tokenAmount;
        tokensAvailabe = tokenTierMax[_tier] - tokenTierCounter[_tier];

        require(weiTotal <= weiAmount, "Calladita: Amount sent is not enough");
        require(tokensAvailabe >= _tokenAmount, "Calladita: No tokens enough for required tier");
    }

    function _preValidateFunding(uint256 weiAmount) internal pure {        
        require(weiAmount != 0, "Calladita: weiAmount is 0");
        //require(block.timestamp <= getEndDate(), "Calladita: crowdfunding period is over");
    }

    function getUserBalance(address user) public view returns(uint256){
        return userBalance[user];
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    // function setEndDate(uint256 _endDate) public onlyOwner() {
    //     endDate = _endDate;      
    // }

    // function getEndDate() public view returns (uint256){
    //   return endDate;
    // }
}
