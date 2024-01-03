pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./EnumerableSet.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./hotpotinterface.sol";
import "./ILoan.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

contract Loan is Ownable, ILoan,ReentrancyGuard,Pausable {
    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    IERC721 public erc721;
    IERC20 public erc20;
    IHotPot public ihotpot;

    address public devAddress;
    address public rewardAddress;

    uint256 public devRatio = 2;
    uint256 public rewardRatio = 4;

    mapping(uint256 => Reservation) public reservations;
    EnumerableSet.UintSet internal loanSet;

    uint256 public thresholdTime = 10 * 60;
    uint256 public maxLoanDay = 365;

    event TokenDeposit(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed start,
        uint256 depositDays,
        uint256 pricePerDay
    );

    event TokenCancelDeposit(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed cancleTime
    );

    event TokenBorrowed(
        address indexed borrower,
        uint256 indexed tokenId,
        address indexed owner,
        uint256 start,
        uint256 borrowDays,
        uint256 pricePerDay,
        uint256 borrowEndTime,
        uint8 grade
    );

    struct Reservation {
        uint256 tokenId;
        address owner;
        address borrower;
        uint256 borrowEndTime; //borrow end time
        uint256 pricePerDay;
        uint256 start; // loan start time
        uint256 times; //loan for how many days

    }

    modifier validNFToken(uint256 _tokenId) {
        require(
            erc721.ownerOf(_tokenId) != address(0),
            "It is not a NFT token!"
        );
        _;
    }

    constructor(address _erc721, address _erc20) public {
        require(_erc721.isContract(), "ERC721 address is not contract!");
        require(_erc20.isContract(), "ERC20 address is contract!");
        erc721 = IERC721(_erc721);
        erc20 = IERC20(_erc20);
        ihotpot = IHotPot(_erc721);
    }

    function setDevAddress(address _dev) external onlyOwner{
        require(_dev!=address(0),"Address can not be 0.");
        devAddress = _dev;
    }

    function setRewardAddress(address _addr) external onlyOwner{
        require(_addr!=address(0),"Address can not be 0.");
        rewardAddress = _addr;
    }
    
    function setRewardRatio(uint256 _ratio) external onlyOwner{
        require(_ratio<10,"Ratio can not be greater than 10!");
        rewardRatio = _ratio;
    }

    function setDevRatio(uint256 _ratio) external onlyOwner{
        require(_ratio<10,"Ratio can not be greater than 10!");
        devRatio = _ratio;
    }

    function checkPrivilege(
        address _user,
        uint256 _tokenId,
        uint256 _time
    ) external override view validNFToken(_tokenId) returns (bool) {
        //if the token is borrowed , the owner can not use it
        Reservation memory r = reservations[_tokenId];

        //The token is not deposited
        if(r.start==0){
            //The user must be the token owner
            return erc721.ownerOf(_tokenId)==_user;
        }
        //The token is deposited
        else{
            if(r.borrower == _user){
                //The borrower is borrowing 
                if(r.borrowEndTime>_time){
                    return true;
                }
            }else{
                if(_user==erc721.ownerOf(_tokenId)){
                    //The deposit end
                    if(r.start + r.times*86400<_time){
                        return true;
                    }
                }
            }
        }
        return false;
    }

    function checkCanSell(
        uint256 _tokenId,
        uint256 _time
    ) external override view validNFToken(_tokenId) returns (bool){
        Reservation memory r = reservations[_tokenId];
        if(r.start==0){
            return true;
        }else{
           if(r.start + r.times*86400<_time){
                return true;
            }
        }
        return false;
    }

    function cancelDeposit(uint256 _tokenId) external whenNotPaused validNFToken(_tokenId) nonReentrant{
        require(
            erc721.ownerOf(_tokenId) == msg.sender,
            "You are not the owner of this token!"
        );
        Reservation memory r = reservations[_tokenId];
        require(r.start != 0,"This token is not deposited!");
        require(r.borrowEndTime<now,"This token is borrowed!");
        delete reservations[_tokenId];
        loanSet.remove(_tokenId);
        emit TokenCancelDeposit(msg.sender,_tokenId,now);
    }

    function getLoanSize() external view returns(uint256){
        return loanSet.length();
    }

    function getLoanList() external view returns (uint256[] memory) {
        uint256 loanSize = loanSet.length();
        uint256[] memory data = new uint256[](loanSize);
        for (uint256 i = 0; i < loanSize; i++) {
            data[i] = loanSet.at(i);
        }
        return data;
    }

    // struct Reservation {
    //     uint256 tokenId;
    //     address borrower;
    //     uint256 borrowEndTime; //borrow end time
    //     uint256 pricePerDay;
    //     uint256 start; // loan start time
    //     uint256 times; //loan for how many days
    // }
    function deposit(
        uint256 _tokenId,
        uint256 _days,
        uint256 _pricePerDay
    ) external validNFToken(_tokenId) whenNotPaused nonReentrant {
        require(_days <= maxLoanDay, "The max loan time is 365 days!");
        require(_days>0,"Can not loan for 0 day!");

        require(
            erc721.ownerOf(_tokenId) == msg.sender,
            "You are not the owner of this token!"
        );

        Reservation memory r = reservations[_tokenId];
        if (r.start != 0) {
            require(
                r.start + r.times * 24 * 60 * 60 < now,
                "This token is in reservation!"
            );
        }

        require(ihotpot.getUseTime(_tokenId)+86400<now,"This member card is used today!");

        reservations[_tokenId].tokenId = _tokenId;
        reservations[_tokenId].start = now;
        reservations[_tokenId].times = _days;
        reservations[_tokenId].owner = msg.sender;
        reservations[_tokenId].borrowEndTime = 0;
        reservations[_tokenId].borrower = address(0);
        reservations[_tokenId].pricePerDay = _pricePerDay;

        loanSet.add(_tokenId);
        emit TokenDeposit(msg.sender, _tokenId, now, _days, _pricePerDay);
    }

    function borrow(uint256 _tokenId, uint256 _days)
        external
        nonReentrant
        whenNotPaused
        validNFToken(_tokenId)
    {
        require(_days < maxLoanDay, "The max loan time is 365 days!");
        Reservation memory r = reservations[_tokenId];
        require(r.start != 0, "This token can not be borrowed!");
        require(
            erc721.ownerOf(_tokenId) != msg.sender,
            "You are the owner of this token!"
        );
        require(r.borrowEndTime < now, "This token is borrowed!");
        require(
            r.start + r.times * 86400 > now +thresholdTime,
            "This token is not loan now!"
        );
        require(
            r.start + r.times * 86400 + 86400 - thresholdTime > now + _days * 86400,
            "This token can not be borrowed for so long!"
        );

        uint256 totalPrice = r.pricePerDay.mul(_days);

        require(erc20.balanceOf(msg.sender)>=totalPrice,"You do not have enough hotpot!");

        uint256 devPrice = totalPrice.mul(devRatio).div(100);
        uint256 rewardPrice = totalPrice.mul(rewardRatio).div(100);

        uint256 loanPrice = totalPrice.sub(rewardPrice).sub(devPrice);

        if(now + _days*86400>r.start + r.times * 86400){
            reservations[_tokenId].borrowEndTime = r.start + r.times * 86400;
        }else{
            reservations[_tokenId].borrowEndTime = now + _days * 86400;
        }
       
        reservations[_tokenId].borrower = msg.sender;

        erc20.safeTransferFrom(msg.sender, devAddress, devPrice);

        erc20.safeTransferFrom(msg.sender, rewardAddress, rewardPrice);

        erc20.safeTransferFrom(msg.sender, erc721.ownerOf(_tokenId), loanPrice);
        uint8 grade = ihotpot.getGrade(_tokenId);
        uint256 endtime = reservations[_tokenId].borrowEndTime;
        emit TokenBorrowed(msg.sender, _tokenId,erc721.ownerOf(_tokenId), now, _days, r.pricePerDay,endtime,grade);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
