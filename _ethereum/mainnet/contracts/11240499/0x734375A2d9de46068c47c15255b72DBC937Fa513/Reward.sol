pragma solidity ^0.6.0;

import "./IERC721Enumerable.sol";
import "./hotpotinterface.sol";
import "./ILoan.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

contract Reward is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    address public devAddress;

    IHotPot public hotpot;
    IERC721Enumerable public erc721;
    IERC20 public erc20;
    ILoan public loan;

    event WithdrawReward(address _user, uint256 _tokenId, uint256 _amount);

    event Rescue(address indexed dst, uint256 sad);
    event RescueToken(address indexed dst, address indexed token, uint256 sad);

    //weight,percent
    uint256 public weightGrade1 = 100;
    uint256 public weightGrade2 = 120;
    uint256 public weightGrade3 = 150;

    //can withdraw total reward daily, percent
    uint256 public availableRewardRatio = 20;

    uint256 public devRewardRatio = 7;

    modifier checkAllAddress() {
        require(hotpot != IHotPot(0), "Contract NFT is not initialized!");
        require(
            erc721 != IERC721Enumerable(0),
            "Contract HotPot is not initialized!"
        );
        require(erc20 != IERC20(0), "Contract is not initialized!");
        _;
    }

    modifier validNFToken(uint256 _tokenId) {
        require(
            erc721.ownerOf(_tokenId) != address(0),
            "It is not a NFT token!"
        );
        _;
    }

    constructor(
        address _dev,
        address _nft,
        address _hotpot
    ) public {
        require(_dev != address(0));
        require(_nft != address(0));
        require(_hotpot != address(0));
        require(_nft.isContract(), "It's not contract address!");
        require(_hotpot.isContract(), "It's not contract address!");

        devAddress = _dev;
        hotpot = IHotPot(_nft);
        erc721 = IERC721Enumerable(_nft);
        erc20 = IERC20(_hotpot);
    }

    function setDevRatio(uint8 _ratio) external onlyOwner {
        require(_ratio < 10, "Dev ratio can not be greater than 10%");
        devRewardRatio = _ratio;
    }

    function setDevAddress(address _dev) external onlyOwner {
        require(_dev != address(0));
        devAddress = _dev;
    }

    function getBalance() external view returns (uint256) {
        return erc20.balanceOf(address(this));
    }

    function setHotPotTicket(address _addr) external onlyOwner {
        require(_addr.isContract(), "It's not contract address!");

        hotpot = IHotPot(_addr);
        erc721 = IERC721Enumerable(_addr);
    }

    function setHotPot(address _addr) external onlyOwner {
        require(_addr.isContract(), "It's not contract address!");
        erc20 = IERC20(_addr);
    }

    function setLoan(address _addr) external onlyOwner {
        require(_addr.isContract(), "It's not contract address!");
        loan = ILoan(_addr);
    }

    function calNormalReward(uint256 _tokenId) external view returns (uint256) {
        if (erc721.totalSupply() == 0) {
            return 0;
        }
        //3.calculate the Reward
        uint256 grade1 = hotpot.getGradeCount(1);
        uint256 grade2 = hotpot.getGradeCount(2);
        uint256 grade3 = hotpot.getGradeCount(3);

        uint8 grade = hotpot.getGrade(_tokenId);

        uint256 totalWeight = grade1 *
            weightGrade1 +
            grade2 *
            weightGrade2 +
            grade3 *
            weightGrade3;
        uint256 weight = weightGrade1;
        if (grade == 1) {
            weight = weightGrade1;
        } else if (grade == 2) {
            weight = weightGrade2;
        } else if (grade == 3) {
            weight = weightGrade3;
        }

        uint256 totalReward = erc20.balanceOf(address(this));
        uint256 available = totalReward.mul(availableRewardRatio).div(100);

        uint256 ratio = weight.mul(100000).div(totalWeight);
        if (ratio > 20000) {
            ratio = 20000;
        }

        uint256 reward = available.mul(ratio).div(100000);
        return reward;
    }

    function calReward(uint256 _tokenId)
        external
        view
        checkAllAddress
        validNFToken(_tokenId)
        returns (uint256)
    {
        //1.check the NFT is used?
        uint256 time = hotpot.getUseTime(_tokenId);
        if (time + 86400 > now) {
            return 0;
        }

        return this.calNormalReward(_tokenId);
    }

    // event WithdrawReward(address _user,uint256 _tokenId, uint256 _amount);

    function getReward(uint256 _tokenId)
        external
        checkAllAddress
        validNFToken(_tokenId)
        nonReentrant
        whenNotPaused
    {
        //1.check the NFT is used?
        uint256 time = hotpot.getUseTime(_tokenId);
        require(time + 86400 < now, "This ticket is used within 24 hours!");

        require(this.getBalance() > 0, "The reward pool is empty!");

        //2. check ownership
        require(
            loan.checkPrivilege(msg.sender, _tokenId, now),
            "You do not have right to use this token!"
        );

        uint256 reward = this.calReward(_tokenId);

        uint256 devReward = reward.mul(devRewardRatio).div(100);
        uint256 userReward = reward.sub(devReward);

        //2.set use
        hotpot.setUse(_tokenId);

        erc20.safeTransfer(devAddress, devReward);
        //send to user and dev
        erc20.safeTransfer(msg.sender, userReward);

        emit WithdrawReward(msg.sender, _tokenId, reward);
    }

    function rescue(address payable to_, uint256 amount_) external onlyOwner {
        require(to_ != address(0), "must not 0");
        require(amount_ > 0, "must gt 0");

        to_.transfer(amount_);
        emit Rescue(to_, amount_);
    }

    function rescue(
        address to_,
        IERC20 token_,
        uint256 amount_
    ) external onlyOwner {
        require(to_ != address(0), "must not 0");
        require(amount_ > 0, "must gt 0");

        token_.transfer(to_, amount_);
        emit RescueToken(to_, address(token_), amount_);
    }

    function pause() external onlyOwner{
        _pause();
    }

    function unpause() external onlyOwner{
        _unpause();
    }
}
