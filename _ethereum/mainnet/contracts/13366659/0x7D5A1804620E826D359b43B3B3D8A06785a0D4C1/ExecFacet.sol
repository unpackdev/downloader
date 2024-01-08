// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./BFacetOwner.sol";
import "./LibAddress.sol";
import "./LibDiamond.sol";
import "./LibExecutor.sol";
import "./EnumerableSet.sol";
import "./GelatoBytes.sol";
import "./GelatoString.sol";
import "./Utils.sol";
import "./FGelato.sol";
import "./IGelatoV1.sol";
import "./CTokens.sol";
import "./IOracleAggregator.sol";

contract ExecFacet is BFacetOwner {
    using LibDiamond for address;
    using LibExecutor for address;
    using GelatoBytes for bytes;
    using EnumerableSet for EnumerableSet.AddressSet;
    using GelatoString for string;

    // solhint-disable var-name-mixedcase
    uint256 public constant GAS_OVERHEAD = 40000;
    IGelatoV1 public immutable GELATO_V1;
    address public immutable GELATO_PROVIDER;

    // solhint-enable var-name-mixedcase

    event LogExecSuccess(
        address indexed executor,
        address indexed service,
        bool indexed wasExecutorPaid
    );

    event LogSetGasMargin(uint256 oldGasMargin, uint256 newGasMargin);

    constructor(IGelatoV1 _gelatoV1, address _gelatoProvider) {
        GELATO_V1 = _gelatoV1;
        GELATO_PROVIDER = _gelatoProvider;
    }

    // ################ Callable by Gov ################
    function addExecutors(address[] calldata _executors) external onlyOwner {
        for (uint256 i; i < _executors.length; i++)
            require(_executors[i].addExecutor(), "ExecFacet.addExecutors");
    }

    function addBundleExecutors(address[] calldata _bundleExecutors)
        external
        onlyOwner
    {
        for (uint256 i; i < _bundleExecutors.length; i++)
            require(
                _bundleExecutors[i].addBundleExecutor(),
                "ExecFacet.addBundleExecutors"
            );
    }

    function removeExecutors(address[] calldata _executors) external {
        for (uint256 i; i < _executors.length; i++) {
            require(
                msg.sender == _executors[i] || msg.sender.isContractOwner(),
                "ExecFacet.removeExecutors: msg.sender ! executor || owner"
            );
            require(
                _executors[i].removeExecutor(),
                "ExecFacet.removeExecutors"
            );
        }
    }

    function removeBundleExecutors(address[] calldata _bundleExecutors)
        external
    {
        for (uint256 i; i < _bundleExecutors.length; i++) {
            require(
                msg.sender == _bundleExecutors[i] ||
                    msg.sender.isContractOwner(),
                "ExecFacet.removeBundleExecutors: msg.sender ! bundleExecutor || owner"
            );
            require(
                _bundleExecutors[i].removeBundleExecutor(),
                "ExecFacet.removeBundleExecutors"
            );
        }
    }

    function setGasMargin(uint256 _gasMargin) external onlyOwner {
        emit LogSetGasMargin(gasMargin(), _gasMargin);
        LibExecutor.setGasMargin(_gasMargin);
    }

    // solhint-disable function-max-lines
    // ################ Callable by Executor ################
    /// @dev * reverts if Executor overcharges users
    ///      * assumes honest executors
    ///      * verifying correct fee can be removed after staking/slashing
    ///        was introduced
    // solhint-disable-next-line code-complexity
    function exec(
        address _service,
        bytes calldata _data,
        address _creditToken
    ) external {
        uint256 startGas = gasleft();

        require(
            msg.sender.isExecutor() || msg.sender.isBundleExecutor(),
            "ExecFacet.exec: onlyExecutors || onlyBundleExecutors"
        );

        if (_service == address(GELATO_V1)) _creditToken = ETH;

        uint256 preCreditTokenBalance = getBalance(_creditToken, address(this));

        (bool success, bytes memory returndata) = _service.call(_data);
        if (!success) returndata.revertWithError("ExecFacet.exec:");

        // Needs to be here in case service relies on GelatoV1 built-in provider ETH payments
        if (_service == address(GELATO_V1))
            GELATO_V1.withdrawExcessExecutorStake(type(uint256).max);

        uint256 postCreditTokenBalance = getBalance(
            _creditToken,
            address(this)
        );

        // TO DO: remove and replace with executor payments based on what services paid out
        require(
            postCreditTokenBalance > preCreditTokenBalance,
            "ExecFacet.exec: postCreditTokenBalance < preCreditTokenBalance"
        );

        uint256 credit = postCreditTokenBalance - preCreditTokenBalance;

        uint256 gasDebitInETH = (startGas - gasleft() + GAS_OVERHEAD) *
            _getCappedGasPrice(LibAddress.getGasPriceOracle());

        uint256 gasDebitInCreditToken;
        if (_creditToken == ETH) gasDebitInCreditToken = gasDebitInETH;
        else {
            (gasDebitInCreditToken, ) = IOracleAggregator(
                LibAddress.getOracleAggregator()
            ).getExpectedReturnAmount(gasDebitInETH, ETH, _creditToken);
        }

        require(
            gasDebitInCreditToken != 0,
            "ExecFacet.exec:  _creditToken not on OracleAggregator"
        );

        uint256 _gasMargin_ = gasMargin();

        require(
            credit <=
                gasDebitInCreditToken +
                    (gasDebitInCreditToken * _gasMargin_) /
                    100,
            "ExecFacet.exec: Executor Overcharged"
        );

        if (_service == address(GELATO_V1))
            if (abi.decode(_data[68:100], (address)) == GELATO_PROVIDER) {
                // solhint-disable no-empty-blocks
                try
                    GELATO_V1.provideFunds{value: credit}(GELATO_PROVIDER)
                {} catch {}
                // solhint-enable no-empty-blocks
            }

        /// TO DO: pay executors based 1:1 on what services paid gelato in ETH equivalents
        (success, ) = msg.sender.call{
            value: gasDebitInETH + (gasDebitInETH * _gasMargin_) / 100
        }("");

        emit LogExecSuccess(msg.sender, _service, success);
    }

    function estimateExecGasDebit(
        address _service,
        bytes calldata _data,
        address _creditToken
    ) external returns (uint256 gasDebitInETH, uint256 gasDebitInCreditToken) {
        uint256 startGas = gasleft();

        require(
            msg.sender.isExecutor() || msg.sender.isBundleExecutor(),
            "ExecFacet.exec: onlyExecutors || onlyBundleExecutors"
        );

        if (_service == address(GELATO_V1)) _creditToken = ETH;

        uint256 preCreditTokenBalance = getBalance(_creditToken, address(this));

        (bool success, bytes memory returndata) = _service.call(_data);
        if (!success) returndata.revertWithError("ExecFacet.exec:");

        // Needs to be here in case service relies on GelatoV1 built-in provider ETH payments
        if (_service == address(GELATO_V1))
            GELATO_V1.withdrawExcessExecutorStake(type(uint256).max);

        uint256 postCreditTokenBalance = getBalance(
            _creditToken,
            address(this)
        );

        uint256 credit = postCreditTokenBalance - preCreditTokenBalance;
        credit;

        gasDebitInETH =
            (startGas - gasleft() + GAS_OVERHEAD) *
            _getCappedGasPrice(LibAddress.getGasPriceOracle());

        if (_creditToken == ETH) gasDebitInCreditToken = gasDebitInETH;
        else {
            (gasDebitInCreditToken, ) = IOracleAggregator(
                LibAddress.getOracleAggregator()
            ).getExpectedReturnAmount(gasDebitInETH, ETH, _creditToken);
        }
    }

    function canExec(address _executor) external view returns (bool) {
        return _executor.canExec();
    }

    function isExecutor(address _executor) external view returns (bool) {
        return _executor.isExecutor();
    }

    function isBundleExecutor(address _bundleExecutor)
        external
        view
        returns (bool)
    {
        return _bundleExecutor.isBundleExecutor();
    }

    function executors() external view returns (address[] memory) {
        return LibExecutor.executors();
    }

    function bundleExecutors() external view returns (address[] memory) {
        return LibExecutor.bundleExecutors();
    }

    function numberOfExecutors() external view returns (uint256) {
        return LibExecutor.numberOfExecutors();
    }

    function numberOfBundleExecutors() external view returns (uint256) {
        return LibExecutor.numberOfBundleExecutors();
    }

    function gasMargin() public view returns (uint256) {
        return LibExecutor.gasMargin();
    }
}
