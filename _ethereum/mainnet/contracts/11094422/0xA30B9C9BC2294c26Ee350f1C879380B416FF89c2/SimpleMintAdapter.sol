pragma solidity ^0.5.0;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a); // dev: overflow
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a); // dev: underflow
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b); // dev: overflow
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0); // dev: divide by zero
        c = a / b;
    }
}

pragma solidity 0.5.17;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IGateway {
    function mint(bytes32 _pHash, uint256 _amount, bytes32 _nHash, bytes calldata _sig) external returns (uint256);
    function burn(bytes calldata _to, uint256 _amount) external returns (uint256);
}

interface IGatewayRegistry {
    function getGatewayBySymbol(string calldata _tokenSymbol) external view returns (IGateway);
    function getTokenBySymbol(string calldata _tokenSymbol) external view returns (IERC20);
}

interface IBTCETHOracle {
    function latestRoundData() external view returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

contract SimpleMintAdapter {
    using SafeMath for uint256;

    IGatewayRegistry public registry;
    IBTCETHOracle public oracle;
    address admin;

    constructor(IGatewayRegistry _registry, IBTCETHOracle _oracle, address _admin) public {
        registry = _registry;
        oracle = _oracle;
        admin = _admin;
    }

    /// @notice Mint renBTC for a user and collect a service fee.
    ///
    /// @param _recipient The address to send renBTC to.
    /// @param _gasFee The amount of renBTC to collect as a gas fee.
    /// @param _serviceFeeRate The amount of bps to collect as a service fee.
    /// @param _amount The amount of RenVM has received to the gateway address.
    /// @param _nHash The nHash value returned by RenVM for this Mint.
    /// @param _sig The sig value returned by RenVM for this Mint.
    ///
    /// @return Nothing.
    function mintRenBTC(
        // Parameters from users
        address _recipient,
        uint256 _gasFee,
        uint256 _serviceFeeRate,
        // Parameters from RenVM
        uint256 _amount,
        bytes32 _nHash,
        bytes calldata _sig
    ) external {
        // Mint renBTC
        bytes32 pHash = keccak256(abi.encode(_recipient, _gasFee, _serviceFeeRate));
        uint256 mintedAmount = registry.getGatewayBySymbol("BTC").mint(pHash, _amount, _nHash, _sig);

        // Apply service fee
        uint256 totalFeeAmount = (mintedAmount.mul(_serviceFeeRate).div(10000)).add(_gasFee);
        uint256 netMintedAmount = mintedAmount.sub(totalFeeAmount);

        registry.getTokenBySymbol("BTC").transfer(_recipient, netMintedAmount);
    }

    /// @notice Mint renBTC, convert some to ETH, send both assets, collect a service fee.
    ///
    /// @param _ethAmount Amount of ETH to swap for.
    /// @param _recipient The address to send renBTC to.
    /// @param _gasFee The amount of renBTC to collect as a gas fee.
    /// @param _serviceFeeRate The amount of bps to collect as a service fee.
    /// @param _amount The amount of RenVM has received to the gateway address.
    /// @param _nHash The nHash value returned by RenVM for this Mint.
    /// @param _sig The sig value returned by RenVM for this Mint.
    ///
    /// @return Nothing.
    function mintRenBTCSendEth(
        // Parameters from users
        uint256 _ethAmount,
        address payable _recipient,
        uint256 _gasFee,
        uint256 _serviceFeeRate,
        // Parameters from RenVM
        uint256 _amount,
        bytes32 _nHash,
        bytes calldata _sig
    ) external {
        // Mint renBTC
        bytes32 pHash = keccak256(abi.encode(_recipient, _gasFee, _serviceFeeRate));
        uint256 mintedAmount = registry.getGatewayBySymbol("BTC").mint(pHash, _amount, _nHash, _sig);

        // Apply service fee
        uint256 totalFeeAmount = (mintedAmount.mul(_serviceFeeRate).div(10000)).add(_gasFee);
        uint256 netMintedAmount = mintedAmount.sub(totalFeeAmount);

        // Calculate swap price using Chainlink's BTC/ETH oracle
        (, int256 answer, , , ) = oracle.latestRoundData();
        uint256 ethBtcCost = _ethAmount.div(uint256(answer));

        // Valid swap amount and enough ETH balance
        if (ethBtcCost < netMintedAmount && _ethAmount <= address(this).balance) {
            registry.getTokenBySymbol("BTC").transfer(_recipient, netMintedAmount.sub(ethBtcCost));
            _recipient.transfer(_ethAmount);
        // Invalid swap amount or not enough ETH in contract. Default to just renBTC
        } else {
            registry.getTokenBySymbol("BTC").transfer(_recipient, netMintedAmount);
        }
    }

    /// @notice Burn renBTC and transfer BTC to a BTC address.
    ///
    /// @param _amount The amount to burn.
    /// @param _dest The address to send BTC.
    ///
    /// @return Nothing.
    function burnRenBTC(uint256 _amount, bytes calldata _dest) external {

        // Transfer tokens from user to contract
        registry.getTokenBySymbol("BTC").transferFrom(msg.sender, address(this), _amount);

        // Apply service fee
        uint256 _serviceFeeRate = 10;
        uint256 totalFeeAmount = _amount.mul(_serviceFeeRate).div(10000);
        uint256 netBurnedAmount = _amount.sub(totalFeeAmount);

        registry.getGatewayBySymbol("BTC").burn(_dest, netBurnedAmount);
    }

    /// @notice Withdraw Ether left in the contract.
    ///
    /// @param _amount The amount to withdraw.
    /// @param _dest The address to send withdrawn tokens.
    ///
    /// @return Nothing.
    function withdrawEther(uint256 _amount, address payable _dest) external {
        require(msg.sender == admin);
        _dest.transfer(_amount);
    }

    /// @notice Withdraw tokens (renBTC) left in the contract.
    ///
    /// @param _token The address of the token to withdraw.
    /// @param _amount The amount to withdraw.
    /// @param _dest The address to send withdrawn tokens.
    ///
    /// @return Nothing.
    function withdrawToken(address _token, uint256 _amount, address _dest) external {
        require(msg.sender == admin);
        IERC20(_token).transfer(_dest, _amount);
    }

    /// @notice Set an address as the admin.
    ///
    /// @param _newAdmin The address of the token to withdraw.
    ///
    /// @return Nothing.
    function changeAdmin(address _newAdmin) external {
        require(msg.sender == admin);
        admin = _newAdmin;
    }

    /// @notice Fallback address
    function() external payable {
    }
}