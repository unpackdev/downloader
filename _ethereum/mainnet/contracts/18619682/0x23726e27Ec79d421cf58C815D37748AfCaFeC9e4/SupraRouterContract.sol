// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ReentrancyGuard.sol";
import "./IDepositContract.sol";
import "./Ownable2Step.sol";
import "./ISupraRouterContract.sol";
import "./CheckContractAddress.sol";

/// @title VRF Router Contract
/// @author Supra Developer
/// @notice You can use this contract to interact with VRF Generator contract & Client contract
/// @dev All function calls are currently implemented without side effects

contract SupraRouterContract is
ReentrancyGuard,
Ownable2Step,
ISupraRouterContract,
CheckContractAddress
{
    /// @dev nonce is an incremental counter which is associated with request
    uint256 internal _nonce = 0;

    /// @dev Generator contract address to forward random number request
    address public _supraGeneratorContract;

    /// @dev To put constraint on generator contract upgradability
    bool private _upgradable;

    ///@dev Deposit Contract address to check fund details of relevant user
    address public _depositContract;
    IDepositContract public depositContract;

    constructor() {
        _upgradable = true;
    }

    ///@notice This function is for updating the Deposit Contract Address
    ///@dev To update deposit contract address
    ///@param _contractAddress contract address of the deposit/new deposit contract
    function updateDepositContract(address _contractAddress)
    external
    onlyOwner
    {
        require(
            isContract(_contractAddress),
            "Deposit contract address cannot be EOA"
        );
        require(
            _contractAddress != address(0),
            "Deposit contract address cannot be a zero address"
        );
        _depositContract = _contractAddress;
        depositContract = IDepositContract(_contractAddress);
    }

    /// @notice This function is updating the generator contract address
    /// @dev To update the generator contract address
    /// @param _contractAddress contract address of new generator contract
    function updateGeneratorContract(address _contractAddress)
    external
    onlyOwner
    {
        require(
            isContract(_contractAddress),
            "Generator contract address cannot be EOA"
        );
        require(
            _contractAddress != address(0),
            "Generator contract address cannot be a zero address"
        );
        require(_upgradable, "Generator contract address cannot be updated");
        _supraGeneratorContract = _contractAddress;
    }

    /// @notice By calling this function updation of generator contract address functionality would stop
    /// @dev It will freeze the upgradability of Generator contract address
    function freezeUpgradability() external onlyOwner {
        _upgradable = false;
    }

    /// @notice It will Generate the random number request to generator contract
    /// @dev It will forward the random number generation request by calling generator contracts function
    /// @param _functionSig A combination of a function and the types of parameters it takes, combined together as a string with no spaces
    /// @param _rngCount Number of random numbers requested
    /// @param _numConfirmations Number of Confirmations
    /// @return _nonce nonce is an incremental counter which is associated with request
    function generateRequest(
        string memory _functionSig,
        uint8 _rngCount,
        uint256 _numConfirmations,
        address _clientWalletAddress
    ) external override nonReentrant returns (uint256) {
        return
        generateRequest(
            _functionSig,
            _rngCount,
            _numConfirmations,
            0,
            _clientWalletAddress
        );
    }

    /// @notice It will Generate the random number request to generator contract with client's randomness added
    /// @dev It will forward the random number generation request by calling generator contracts function which takes seed value other than required parameter to add randomness
    /// @param _functionSig A combination of a function and the types of parameters it takes, combined together as a string with no spaces
    /// @param _rngCount Number of random numbers requested
    /// @param _numConfirmations Number of Confirmations
    /// @param _clientSeed Use of this is to add some extra randomness
    /// @return _nonce nonce is an incremental counter which is associated with request
    function generateRequest(
        string memory _functionSig,
        uint8 _rngCount,
        uint256 _numConfirmations,
        uint256 _clientSeed,
        address _clientWalletAddress
    ) public override returns (uint256) {
        //_functionSig should be in a format such that it should carry the parameter type altogether
        require(
            depositContract.isContractEligible(
                _clientWalletAddress,
                msg.sender
            ),
            "Contract not eligible to request"
        );
        require(
            !depositContract.isMinimumBalanceReached(_clientWalletAddress),
            "Insufficient Funds: Minimum balance reached for request"
        );

        bytes memory _functionSigbytes = bytes(_functionSig);
        require(_rngCount > 0, "Invalid rngCount");
        require(_numConfirmations >= 0, "Invalid numConfirmations");
        require(_functionSigbytes.length > 0, "Invalid functionSig");
        _nonce++;
        // we want to cap the number of confirmations to 20
        if (_numConfirmations == 0) {
            _numConfirmations = 1;
        } else if (_numConfirmations > 20) {
            _numConfirmations = 20;
        }
        uint256 nonce_ = _nonce;
        (bool _success, bytes memory _data) = _supraGeneratorContract.call(
            abi.encodeWithSignature(
                "rngRequest(uint256,string,uint8,address,uint256,uint256,address)",
                nonce_,
                _functionSig,
                _rngCount,
                msg.sender,
                _numConfirmations,
                _clientSeed,
                _clientWalletAddress
            )
        );
        require(_success, "Generator Contract call failed");
        return _nonce;
    }

    /// @notice This is the call back function to serve random number request
    /// @dev This function will be called from generator contract address to fulfill random number request which goes to client contract
    /// @param nonce nonce is an incremental counter which is associated with request
    /// @param _clientContractAddress Actual contract address from which request has been generated
    /// @param _functionSig A combination of a function and the types of parameters it takes, combined together as a string with no spaces
    /// @return success bool variable which shows the status of request
    /// @return data data getting from client contract address
    function rngCallback(
        uint256 nonce,
        uint256[] memory rngList,
        address _clientContractAddress,
        string memory _functionSig
    ) public returns (bool, bytes memory) {
        require(
            msg.sender == _supraGeneratorContract,
            "Caller cannot generate the callback"
        );
        (bool success, bytes memory data) = _clientContractAddress.call(
            abi.encodeWithSignature(_functionSig, nonce, rngList)
        );
        return (success, data);
    }
}
