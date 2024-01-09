// SPDX-License-Identifier: MIT
// Sidus PreSale
pragma solidity 0.8.11;
import "Ownable.sol";
import "IERC20.sol";
import "SafeERC20.sol";

contract SidusPreSale is Ownable {
    using SafeERC20 for IERC20;
    
    struct LimitItem {
        uint256 tokenId;
        uint256 limit;
    }

    struct CardsSupply {
        uint256 maxTotalSupply;
        uint256 currentSupply;
    }

    struct Price {
        uint256 value;
        uint256 decimals;
    }

    
    uint256 public CARDS_PER_USER;
    address public beneficiary;
    uint256 public activeAfter;      // date of start presale
    uint256 public closedAfter;      // date of end presalr


    // maping from user  to limits
    mapping(address =>  LimitItem[]) public whiteList;

    // mapping erc20 to 1155 tokenId to card price in this erc20
    mapping(address => mapping(uint256 => Price)) public priceForCard;

    mapping(uint256 => CardsSupply) public maxTotalSupply;


    event Purchase(
        address indexed user, 
        address indexed erc20, 
        uint256  amount
    );

    constructor (address _beneficiary, uint256 _activeAfter, uint256 _closedAfter) {
        require(_beneficiary != address(0), "No zero addess");
        beneficiary = _beneficiary;
        activeAfter = _activeAfter; 
        closedAfter = _closedAfter;
        CARDS_PER_USER = 10;
    }

    function registerForPreSale(address _erc20, LimitItem[] calldata _wanted) external {
        uint256 currLimit;
        uint256 userDebt;
        require(block.timestamp >= activeAfter, "Cant buy before start");
        require(block.timestamp <= closedAfter, "Cant buy after closed"); 
        for (uint256 i = 0; i < _wanted.length; i ++){
            currLimit = _getUserLimitTotal(msg.sender);
            require(priceForCard[_erc20][_wanted[i].tokenId].value > 0, 
                "Cant buy with this token"
            );
            require(
                (currLimit + _addLimitForCard(msg.sender, _wanted[i].tokenId, _wanted[i].limit)) <= CARDS_PER_USER,
                "Purchase limit exceeded"
            );
            userDebt += _getERC20AmountPerItem(_erc20, _wanted[i]);
            require(
                (_wanted[i].limit + maxTotalSupply[_wanted[i].tokenId].currentSupply) 
                    <= maxTotalSupply[_wanted[i].tokenId].maxTotalSupply,
                "Max Total Supply limit exceeded"
            );
            maxTotalSupply[_wanted[i].tokenId].currentSupply += _wanted[i].limit; 

        }

        IERC20(_erc20).safeTransferFrom(msg.sender, beneficiary, userDebt);
        emit Purchase(msg.sender, _erc20, userDebt);
    }
    
    ///////////////////////////////////////////////////////////////////
    /////  Owners Functions ///////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////

    function registerUserForPreSale(address _erc20, LimitItem[] calldata _wanted, address _user) external onlyOwner {
        uint256 currLimit;
        for (uint256 i = 0; i < _wanted.length; i ++){
            currLimit = _getUserLimitTotal(_user);
            require(priceForCard[_erc20][_wanted[i].tokenId].value > 0, 
                "Cant buy with this token"
            );
            require(
                (currLimit + _addLimitForCard(_user, _wanted[i].tokenId, _wanted[i].limit)) <= CARDS_PER_USER,
                "Purchase limit exceeded"
            );
            require(
                _wanted[i].limit + maxTotalSupply[_wanted[i].tokenId].currentSupply <= maxTotalSupply[_wanted[i].tokenId].maxTotalSupply,
                "Max Total Supply limit exceeded"
            );
            maxTotalSupply[_wanted[i].tokenId].currentSupply += _wanted[i].limit; 

        }
        emit Purchase(_user, _erc20, 0);
    }

    function setStartStop(uint256 _activeAfter, uint256 _closedAfter) external onlyOwner {
        activeAfter = _activeAfter; 
        closedAfter = _closedAfter;
    }

    function setBeneficiary(address _beneficiary) external onlyOwner {
        require(_beneficiary != address(0), "No zero addess");
        beneficiary = _beneficiary;
    }

    function setCardsPerUser(uint256 _cardsCount) external onlyOwner {
        CARDS_PER_USER = _cardsCount;
    }

    function setERC20Price(
        address _erc20, 
        uint256 _tokenId, 
        uint256 _newPriceValue, 
        uint256 _newPriceDecimals
    ) 
        external onlyOwner 
    {
        priceForCard[_erc20][_tokenId].value = _newPriceValue;
        priceForCard[_erc20][_tokenId].decimals = _newPriceDecimals;
    }

    function setMaxTotalSupply( uint256 _tokenId, uint256 _cardsCount) external onlyOwner {
        maxTotalSupply[_tokenId].maxTotalSupply = _cardsCount;
    }
    ///////////////////////////////////////////////////////////////////

    function getCardPrice(address _erc20, uint256 _tokenId) external view returns (Price memory) {
        return priceForCard[_erc20][_tokenId];
    }

    function getUserLimitsInfo(address _user) external view returns (LimitItem[] memory) {
        return whiteList[_user];
    }
    
    function getUserLimitTotal(address _user) external view returns (uint256) {
        return _getUserLimitTotal(_user);
    }

    function getUserLimitForCard(address _user, uint256 _tokenId) external view returns (uint256) {
        return _getUserLimitForCard(_user, _tokenId);
    }

    function getERC20Amount(address _erc20, LimitItem[] calldata _wanted) external view returns (uint256 erc20Amount) {
        for (uint256 i = 0; i < _wanted.length; i ++){
            erc20Amount += _getERC20AmountPerItem(_erc20, _wanted[i]);
        }

    }


    ///////////////////////////////////////////////////////////////////
    /////  Internal Functions /////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////

    function _addLimitForCard(address _user, uint256 _tokenId, uint256 _increment)  
        internal 
        returns (uint256 increment)
    {
        for (uint256 i = 0; i < whiteList[_user].length; i ++){
            if (whiteList[_user][i].tokenId == _tokenId) {
               whiteList[_user][i].limit += _increment;
               increment =  _increment;
               break;
            }
        }
        
        // if newLimit == 0  means that there is NO record
        // in array for this tokenId yet. So we need  add it
        if (increment == 0){
            whiteList[_user].push(LimitItem({
                tokenId: _tokenId,
                limit: _increment
            }));
            increment = _increment;
        }
    }

    function _getUserLimitForCard(address _user, uint256 _tokenId) internal view returns (uint256 limit) {
        for (uint256 i = 0; i < whiteList[_user].length; i ++){
            if (whiteList[_user][i].tokenId == _tokenId) {
                limit += whiteList[_user][i].limit;
            }
        }
    }

    function _getUserLimitTotal(address _user) internal view returns (uint256 limit) {
        for (uint256 i = 0; i < whiteList[_user].length; i ++){
                limit += whiteList[_user][i].limit;
        }
    }

    
    function _getERC20AmountPerItem(address _erc20, LimitItem calldata _wanted) internal view returns(uint256) {
        return _wanted.limit 
            * priceForCard[_erc20][_wanted.tokenId].value 
            / priceForCard[_erc20][_wanted.tokenId].decimals;
    }
}