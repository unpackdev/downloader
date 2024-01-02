// contracts/FlashLoan.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./FlashLoanSimpleReceiverBase.sol";
import "./IPoolAddressesProvider.sol";
import "./IERC20.sol";

interface IDex {
    function simpleTrades() external;
}

contract FlashLoanArbitrage is FlashLoanSimpleReceiverBase {
    address payable owner;

    // Aave ERC20 Token addresses
    // address public daiAddress;
    // address public daiAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    // address public usdcAddress;
    // address public usdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public dexContractAddress;

    IERC20 private dai;
    IERC20 private usdc;
    IDex private dexContract;

    constructor(
        address _addressProvider,
        address _dexContractAddress,
        address _daiAddress,
        address _usdcAddress
    ) FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider)) {
        owner = payable(msg.sender);

        dai = IERC20(_daiAddress);
        usdc = IERC20(_usdcAddress);
        dexContractAddress = _dexContractAddress;
        dexContract = IDex(_dexContractAddress);
    }

    function setDexContract(address _contract) external {
        require(
            _contract != address(0),
            "Router address must not be zero address"
        );
        dexContract = IDex(_contract);
    }

    function setQuoteToken(address _token) external {
        require(_token != address(0), "Token must be balid");
        dai = IERC20(_token);
    }

    function setBaseToken(address _token) external {
        require(_token != address(0), "Token must be balid");
        usdc = IERC20(_token);
    }

    /**
        This function is called after your contract has received the flash loaned amount
     */
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        //
        // This contract now has the funds requested.
        // Your logic goes here.
        //

        // Arbirtage operation
        dexContract.simpleTrades();

        // At the end of your logic above, this contract owes
        // the flashloaned amount + premiums.
        // Therefore ensure your contract has enough to repay
        // these amounts.

        // Approve the Pool contract allowance to *pull* the owed amount
        uint256 amountOwed = amount + premium;
        IERC20(asset).approve(address(POOL), amountOwed);

        return true;
    }

    function requestFlashLoan(address _token, uint256 _amount) public {
        address receiverAddress = address(this);
        address asset = _token;
        uint256 amount = _amount;
        bytes memory params = "";
        uint16 referralCode = 0;

        POOL.flashLoanSimple(
            receiverAddress,
            asset,
            amount,
            params,
            referralCode
        );
    }

    function approveUSDC(uint256 _amount) external returns (bool) {
        return usdc.approve(dexContractAddress, _amount);
    }

    function allowanceUSDC() external view returns (uint256) {
        return usdc.allowance(address(this), dexContractAddress);
    }

    function approveDAI(uint256 _amount) external returns (bool) {
        return dai.approve(dexContractAddress, _amount);
    }

    function allowanceDAI() external view returns (uint256) {
        return dai.allowance(address(this), dexContractAddress);
    }

    function getBalance(address _tokenAddress) external view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    function withdraw(address _tokenAddress) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    receive() external payable {}
}
