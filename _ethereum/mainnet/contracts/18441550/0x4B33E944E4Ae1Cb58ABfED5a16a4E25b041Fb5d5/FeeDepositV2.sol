// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IFeeReceiver.sol";
import "./IVoterProxy.sol";
import "./IBooster.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";



contract FeeDepositV2 {
    using SafeERC20 for IERC20;

    address public constant vlcvx = address(0x72a19342e8F1838460eBFCCEf09F6585e32db86E);

    //tokens
    address public immutable prisma;
    address public immutable veProxy;
    address public immutable cvxPrisma;
    
    uint256 public constant denominator = 10000;
    uint256 public callIncentive = 100;
    uint256 public platformIncentive = 5000;
    uint256 public vlcvxIncentive = 0;
    address public platformReceiver;
    address public vlcvxReceiver;
    address public cvxPrismaReceiver;
    address public feeClaimer;

    mapping(address => bool) public distributors;
    mapping(address => bool) public requireProcessing;
    bool public UseDistributors;

    event SetCallIncentive(uint256 _amount);
    event SetvlCvxIncentive(uint256 _amount);
    event SetPlatformIncentive(uint256 _amount);
    event SetPlatformReceiver(address _account);
    event SetvlCvxReceiver(address _account);
    event SetCvxPrismaReceiver(address _account);
    event SetFeeClaimer(address _claimer);
    event AddDistributor(address indexed _distro, bool _valid);
    event PlatformFeesDistributed(address indexed token, uint256 amount);
    event VlcvxFeesDistributed(address indexed token, uint256 amount);
    event RewardsDistributed(address indexed token, uint256 amount);

    constructor(address _proxy, address _prisma, address _cvxprisma, address _initialReceiver) {
        veProxy = _proxy;
        prisma = _prisma;
        cvxPrisma = _cvxprisma;
        platformReceiver = address(0x1389388d01708118b497f59521f6943Be2541bb7);
        cvxPrismaReceiver = _initialReceiver;
        requireProcessing[_initialReceiver] = true;

        UseDistributors = true;
        distributors[msg.sender] = true;
        emit AddDistributor(msg.sender, true);
    }

    modifier onlyOwner() {
        require(IBooster(IVoterProxy(veProxy).operator()).owner() == msg.sender, "!owner");
        _;
    }

    function setDistributor(address _distro, bool _valid) external onlyOwner{
        distributors[_distro] = _valid;
        emit AddDistributor(_distro, _valid);
    }

    function setUseDistributorList(bool _use) external onlyOwner{
        UseDistributors = _use;
    }

    function setCallIncentive(uint256 _incentive) external onlyOwner{
        require(_incentive <= 100, "too high");
        callIncentive = _incentive;
        emit SetCallIncentive(_incentive);
    }

    function setPlatformIncentive(uint256 _incentive) external onlyOwner{
        require(_incentive <= 5000, "too high");
        platformIncentive = _incentive;
        emit SetPlatformIncentive(_incentive);
    }

    function setvlCvxIncentive(uint256 _incentive) external onlyOwner{
        require(_incentive <= 5000, "too high");
        vlcvxIncentive = _incentive;
        emit SetvlCvxIncentive(_incentive);
    }

    function cvxPrismaIncentive() external view returns(uint256){
        return denominator - platformIncentive - vlcvxIncentive - callIncentive;
    }

    function setPlatformReceiver(address _receiver, bool _requireProcess) external onlyOwner{
        platformReceiver = _receiver;
        requireProcessing[_receiver] = _requireProcess;
        emit SetPlatformReceiver(_receiver);
    }

    function setvlCvxReceiver(address _receiver, bool _requireProcess) external onlyOwner{
        vlcvxReceiver = _receiver;
        requireProcessing[_receiver] = _requireProcess;
        emit SetvlCvxReceiver(_receiver);
    }

    function setCvxPrismaReceiver(address _receiver, bool _requireProcess) external onlyOwner{
        cvxPrismaReceiver = _receiver;
        requireProcessing[_receiver] = _requireProcess;
        emit SetCvxPrismaReceiver(_receiver);
    }

    function setFeeClaimer(address _claimer) external onlyOwner{
        feeClaimer = _claimer;
        emit SetFeeClaimer(_claimer);
    }

    function rescueToken(address _token, address _to) external onlyOwner{
        require(_token != prisma, "not allowed");

        uint256 bal = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(_to, bal);
    }

    function processFees() external {
        if(UseDistributors){
            require(distributors[msg.sender], "!auth");
        }

        //call a "fee claimer" to pull prisma boost fees to this distributor
        //keep logic in the claimer so that updates can be made on how to handle locks
        if(feeClaimer != address(0)){
            IFeeReceiver(feeClaimer).processFees();
        }

        //remove call incentive first
        if(callIncentive > 0){
            uint256 callAmount = IERC20(prisma).balanceOf(address(this)) * callIncentive / denominator;
            if(callAmount > 0){
                IERC20(prisma).safeTransfer(msg.sender, callAmount);
            }
        }

        uint256 prismaBalance = IERC20(prisma).balanceOf(address(this));

        //platform
        uint256 distroAmount = prismaBalance * platformIncentive / denominator;

        //process platform
        if(distroAmount > 0){
            IERC20(prisma).safeTransfer(platformReceiver, distroAmount);
            if(requireProcessing[platformReceiver]){
                IFeeReceiver(platformReceiver).processFees();
            }
            emit PlatformFeesDistributed(prisma,distroAmount);
        }

        //vlcvx
        distroAmount = prismaBalance * vlcvxIncentive / denominator;

        //process vlcvx
        if(distroAmount > 0){
            IERC20(prisma).safeTransfer(vlcvxReceiver, distroAmount);
            if(requireProcessing[vlcvxReceiver]){
                IFeeReceiver(vlcvxReceiver).processFees();
            }
            emit VlcvxFeesDistributed(prisma,distroAmount);
        }

        //send rest to cvxprisma incentives
        distroAmount = IERC20(prisma).balanceOf(address(this));
        IERC20(prisma).safeTransfer(cvxPrismaReceiver, distroAmount);
        if(requireProcessing[cvxPrismaReceiver]){
            IFeeReceiver(cvxPrismaReceiver).processFees();
        }

        emit RewardsDistributed(prisma, distroAmount);
    }

}