//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./MerkleProof.sol";
import "./IERC20.sol";

contract FWBPresale is Ownable, ReentrancyGuard {
    using Address for address payable;
    
    // additional params
    uint256 public openingTime;                                 // opening time in unix epoch seconds   
    uint256 public fcfsTime;                                    // fcfs time in unix epoch seconds      
    uint256 public closingTime;                                 // closing time in unix epoch seconds   
    uint256 public minContributionAmount;                       // Min Contribution in ether            
    uint256 public maxContributionAmountWL;                     // Max Contribution in ether            
    uint256 public maxContributionAmountFCFS;                   // Max Contribution in ether            
    uint256 public HARDCAP;                                     // hardcap, in ETH
    uint256 public TOTAL_FWB_PRESALE;                           // amount of FWB available on the presale
    uint256 public totalContributed;                            // total amount contributed, in ETH
    address payable public WALLET;                              // multisig wallet where contributed ETH is stored
    mapping(bool => mapping(address => uint256)) private contributionsETH;

     // whitelist
    bytes32 public merkleRoot;

    // events
    event Contributed(address indexed user, uint256 weiAmount, uint256 timestamp, bool isWL);

    constructor(
        uint256 _openingTime,
        uint256 _fcfsTime,
        uint256 _closingTime,
        uint256 _minContributionAmount,
        uint256 _maxContributionAmountWL,
        uint256 _maxContributionAmountFCFS,
        uint256 _HARDCAP,
        uint256 _TOTAL_FWB_PRESALE,
        address _WALLET
    )
        Ownable(msg.sender)
    {
        require(_openingTime >= block.timestamp, "FWBPresale: opening time is before current time");
        require(_fcfsTime >= _openingTime, "FWBPresale: fcfs time is before opening time");
        require(_closingTime > _fcfsTime, "FWBPresale: fcfs time is not before closing time");
        require(_minContributionAmount > 0, "FWBPresale: minimum contribution must be greater than zero");
        require(_maxContributionAmountWL > _minContributionAmount, "FWBPresale: maximum contribution for WL must be greater than minimum contribution");
        require(_maxContributionAmountFCFS > _minContributionAmount, "FWBPresale: maximum contribution for FCFS must be greater than minimum contribution");
        require(_HARDCAP > 0, "FWBPresale: hardcap must be greater than zero");
        require(_TOTAL_FWB_PRESALE > 0, "FWBPresale: total FWB presale must be greater than zero");
        require(_WALLET != address(0), "FWBPresale: wallet must be different than zero address");

        openingTime = _openingTime;
        fcfsTime = _fcfsTime;
        closingTime = _closingTime;
        minContributionAmount = _minContributionAmount;
        maxContributionAmountWL = _maxContributionAmountWL;
        maxContributionAmountFCFS = _maxContributionAmountFCFS;
        HARDCAP = _HARDCAP;
        TOTAL_FWB_PRESALE = _TOTAL_FWB_PRESALE;
        WALLET = payable(_WALLET);

    }

    receive() external payable {
         revert("This contract does not accept ETH");
    }
    
    // ONLYOWNER FUNCTIONS
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setOpeningTime(uint256 _openingTime) external onlyOwner {
        require(!isOpen(), "FWBPresale: presale is opened already");
        require(_openingTime >= block.timestamp, "FWBPresale: opening time is before current time");
        require(fcfsTime >= _openingTime, "FWBPresale: fcfs time is before opening time");
        openingTime = _openingTime;
    }

    function setFCFSTime(uint256 _fcfsTime) external onlyOwner {
        require(!isFCFS(), "FWBPresale: fcfs is opened already");
        require(_fcfsTime >= block.timestamp, "FWBPresale: fcfs time is before current time");
        require(_fcfsTime >= openingTime, "FWBPresale: fcfs time is before opening time");
        require(closingTime > _fcfsTime, "FWBPresale: fcfs time is not before closing time");
        fcfsTime = _fcfsTime;
    }

    function setClosingTime(uint256 _closingTime) external onlyOwner {
        require(block.timestamp <= closingTime, "FWBPresale: presale is closed already");
        require(_closingTime >= block.timestamp, "FWBPresale: closing time is before current time");
        require(_closingTime > fcfsTime, "FWBPresale: fcfs time is not before closing time");
        closingTime = _closingTime;
    }

    function setMinContributionAmount(uint256 _minContributionAmount) external onlyOwner {
        require(!isOpen(), "FWBPresale: presale is opened already");
        require(_minContributionAmount > 0, "FWBPresale: minimum contribution must be greater than zero");
        require(maxContributionAmountWL > _minContributionAmount, "FWBPresale: maximum contribution for WL must be greater than minimum contribution");
        require(maxContributionAmountFCFS > _minContributionAmount, "FWBPresale: maximum contribution for FCFS must be greater than minimum contribution");
        minContributionAmount = _minContributionAmount;
    }

    function setMaxContributionAmountWL(uint256 _maxContributionAmountWL) external onlyOwner {
        require(!isOpen(), "FWBPresale: presale is opened already");
        require(_maxContributionAmountWL > minContributionAmount, "FWBPresale: maximum contribution for WL must be greater than minimum contribution");
        maxContributionAmountWL = _maxContributionAmountWL;
    }

    function setMaxContributionAmountFCFS(uint256 _maxContributionAmountFCFS) external onlyOwner {
        require(!isOpen(), "FWBPresale: presale is opened already");
        require(_maxContributionAmountFCFS > minContributionAmount, "FWBPresale: maximum contribution for FCFS must be greater than minimum contribution");
        maxContributionAmountFCFS = _maxContributionAmountFCFS;
    }

    function recoverETH(uint256 _weiAmount) external onlyOwner {
        require(_weiAmount <= address(this).balance, "Insufficient balance in the contract");
        _forwardFunds(_weiAmount);
    }

    function recoverERC20Tokens(address tokenAddress, uint256 amount) external nonReentrant onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(WALLET, amount);
    }


    // PUBLIC VIEW FUNCTIONS
    function isFCFS() public view returns (bool) {
        return block.timestamp >= fcfsTime && block.timestamp <= closingTime;
    }

    function isOpen() public view returns (bool) {
        return block.timestamp >= openingTime && block.timestamp <= closingTime;
    }

    function FWBBought(address user) public view returns (uint256) {
        return ((contributionsETH[true][user] + contributionsETH[false][user]) * TOTAL_FWB_PRESALE) / HARDCAP;
    }

    function contributionsETHWL(address user) public view returns (uint256) {
        return contributionsETH[true][user];
    }

    function contributionsETHFCFS(address user) public view returns (uint256) {
        return contributionsETH[false][user];
    }


    // INTERNAL FUNCTIONS
    function _forwardFunds(uint256 weiAmount) internal nonReentrant {
        WALLET.sendValue(weiAmount);
    }


    //PUBLIC FUNCTIONS
    function contribute(bytes32[] memory _merkleProof) public payable {

        // first, declare some necessary memory variables
        address _user = msg.sender;
        uint256 _weiAmount = msg.value;
        bool _addressWhitelisted = false;
        bool _isWL = !isFCFS();

        // then make a few checks and stop if any aren't true to avoid further gas spending
        require(isOpen(), "FWBPresale: not open");
        require(_weiAmount >= minContributionAmount, "FWBPresale: contribution below minimum");
        require(totalContributed + _weiAmount <= HARDCAP, "FWBPresale: hardcap reached with that contribution");
        require(merkleRoot != 0, "FWBPresale: missing root");

        // check if address belongs in whitelist
        bytes32 leaf = keccak256(abi.encodePacked(_user));
        _addressWhitelisted = MerkleProof.verify(_merkleProof, merkleRoot, leaf);

        // check last details
        if (_isWL){
            require(_addressWhitelisted, "FWBPresale: this address is not whitelisted");
            require(contributionsETH[_isWL][_user] + _weiAmount <= maxContributionAmountWL, "FWBPresale: user's WL cap exceeded");
        }
        else {
            require(contributionsETH[_isWL][_user] + _weiAmount <= maxContributionAmountFCFS, "FWBPresale: user's FCFS cap exceeded");
        }

        //contribute the funds
        _forwardFunds(_weiAmount);

        //update total contributions
        totalContributed = totalContributed + _weiAmount;
        emit Contributed(_user, _weiAmount, block.timestamp, _isWL);

        //update user's contributions
        contributionsETH[_isWL][_user] += _weiAmount;

    }
}