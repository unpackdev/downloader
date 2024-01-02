// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Initializable.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./ERC20Upgradeable.sol";
import "./AccessControl.sol";
import "./IERC721Receiver.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./factory.sol";
import "./emitter.sol";
import "./helper.sol";

interface IERC20Extented is IERC20 {
    function decimals() external view returns (uint8);
}

/// @title StationX Governance Token Contract
/// @dev Base Contract as a reference for DAO Governance Token contract proxies
contract ERC20DAO is
    ERC20Upgradeable,
    AccessControl,
    IERC721Receiver,
    ReentrancyGuard,
    Helper
{
    using SafeERC20 for IERC20;

    ///@dev address of the emitter contract
    address public emitterContractAddress;

    address public factoryAddress;

    ERC20DAOdetails public erc20DaoDetails;

    /// @dev initialize Function to initialize Token contract
    function initializeERC20(
        address _factory,
        address _emitter,
        string memory _DaoName,
        string memory _DaoSymbol,
        uint256 _quorum,
        uint256 _threshold,
        bool _isGovernanceActive,
        bool _isTransferable,
        address _ownerAddress,
        bool onlyAllowWhitelist
    ) external initializer {
        factoryAddress = _factory;
        emitterContractAddress = _emitter;
        ERC20DAOdetails memory _erc20DaoDetails = ERC20DAOdetails(
            _DaoName,
            _DaoSymbol,
            _quorum,
            _threshold,
            _isGovernanceActive,
            _isTransferable,
            onlyAllowWhitelist,
            _ownerAddress
        );
        erc20DaoDetails = _erc20DaoDetails;

        __ERC20_init(_DaoName, _DaoSymbol);
    }

    /// @dev This function returns details of a particular dao
    function getERC20DAOdetails()
        external
        view
        returns (ERC20DAOdetails memory)
    {
        return erc20DaoDetails;
    }

    /// @dev Function execute proposals called by gnosis safe
    /// @param _data function signature data encoded along with parameters
    function updateProposalAndExecution(
        address _contract,
        bytes memory _data
    ) external onlyGnosis(factoryAddress, address(this)) nonReentrant {
        if (_contract == address(0))
            revert AddressInvalid("_contract", _contract);
        (bool success, ) = _contract.call(_data);
        require(success);
    }

    /// @dev Function to transfer NFT from this contract
    /// @param _nft address of nft to transfer
    /// @param _to address of receiver
    /// @param _tokenId tokenId of nft to transfer
    function transferNft(
        address _nft,
        address _to,
        uint256 _tokenId
    ) external onlyCurrentContract {
        if (_nft == address(0)) revert AddressInvalid("_nft", _nft);
        if (_to == address(0)) revert AddressInvalid("_to", _to);
        IERC721(_nft).safeTransferFrom(address(this), _to, _tokenId);
    }

    /// @dev function to mint GT token to a addresses
    /// @param _amountArray array of amount to be transferred
    /// @param _userAddress array of address where the amount should be transferred
    function mintGTToAddress(
        uint256[] memory _amountArray,
        address[] memory _userAddress
    ) external onlyCurrentContract {
        if (_amountArray.length != _userAddress.length)
            revert ArrayLengthMismatch(
                _amountArray.length,
                _userAddress.length
            );

        uint256 leng = _amountArray.length;
        for (uint256 i; i < leng; ) {
            _mint(_userAddress[i], _amountArray[i]);
            Emitter(emitterContractAddress).newUser(
                address(this),
                _userAddress[i],
                Factory(factoryAddress)
                    .getDAOdetails(address(this))
                    .depositTokenAddress,
                0,
                block.timestamp,
                _amountArray[i],
                Safe(
                    Factory(factoryAddress)
                        .getDAOdetails(address(this))
                        .gnosisAddress
                ).isOwner(_userAddress[i])
            );

            unchecked {
                ++i;
            }
        }

        Emitter(emitterContractAddress).mintGTToAddress(
            address(this),
            _amountArray,
            _userAddress
        );
    }

    /// @dev function to update governance settings
    /// @param _quorum update quorum into the contract
    /// @param _threshold update threshold into the contract
    function updateGovernanceSettings(
        uint256 _quorum,
        uint256 _threshold
    ) external onlyCurrentContract {
        if (_quorum == 0) revert AmountInvalid("_quorum", _quorum);
        if (_threshold == 0) revert AmountInvalid("_threshold", _threshold);

        if (!(_quorum <= FLOAT_HANDLER_TEN_4))
            revert AmountInvalid("_quorum", _quorum);
        if (!(_threshold <= FLOAT_HANDLER_TEN_4))
            revert AmountInvalid("_threshold", _threshold);

        erc20DaoDetails.quorum = _quorum;
        erc20DaoDetails.threshold = _threshold;

        Emitter(emitterContractAddress).updateGovernanceSettings(
            address(this),
            _quorum,
            _threshold
        );
    }

    /// @dev Function to set whitelist to true for a particular token contract
    function toggleOnlyAllowWhitelist() external payable onlyCurrentContract {
        erc20DaoDetails.onlyAllowWhitelist = !erc20DaoDetails
            .onlyAllowWhitelist;
    }

    /// @dev Function to change governance active
    /// @param _isGovernanceActive New governance active status
    function updateGovernanceActive(
        bool _isGovernanceActive
    ) external payable onlyCurrentContract {
        erc20DaoDetails.isGovernanceActive = _isGovernanceActive;
    }

    /// @dev Function to update token transferability for a particular token contract
    /// @param _isTokenTransferable New token transferability
    function updateTokenTransferability(
        bool _isTokenTransferable
    ) external payable onlyCurrentContract {
        erc20DaoDetails.isTransferable = _isTokenTransferable;

        Emitter(emitterContractAddress).updateTokenTransferability(
            address(this),
            _isTokenTransferable
        );
    }

    /// @dev Function to override transfer to restrict token transfers
    function transfer(
        address to,
        uint256 amount
    ) public virtual override(ERC20Upgradeable) returns (bool) {
        require(erc20DaoDetails.isTransferable, "Token Non Transferable");

        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /// @dev Function to override transferFrom to restrict token transfers
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override(ERC20Upgradeable) returns (bool) {
        require(erc20DaoDetails.isTransferable, "Token Non Transferable");

        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /// @dev Function to mint Governance Token and assign delegate
    /// @param to Address to which tokens will be minted
    /// @param amount Value of tokens to be minted based on deposit by DAO member
    function mintToken(
        address to,
        uint256 amount,
        bytes32[] calldata _merkleProof
    ) public {
        if (erc20DaoDetails.onlyAllowWhitelist) {
            require(
                MerkleProof.verify(
                    _merkleProof,
                    Factory(factoryAddress)
                        .getDAOdetails(address(this))
                        .merkleRoot,
                    keccak256(abi.encodePacked(to))
                ),
                "Incorrect proof"
            );
        }
        require(msg.sender == factoryAddress || msg.sender == address(this));
        _mint(to, amount);
    }

    // -- Who will have access control for burning tokens?
    /// @dev Function to burn Governance Token
    /// @param account Address from where token will be burned
    /// @param amount Value of tokens to be burned
    function burnToken(address account, uint256 amount) internal {
        _burn(account, amount);
    }

    /// @dev Internal function that needs to be override
    function _msgSender()
        internal
        view
        virtual
        override(Context, ContextUpgradeable)
        returns (address)
    {
        return msg.sender;
    }

    function _msgData()
        internal
        view
        virtual
        override(Context, ContextUpgradeable)
        returns (bytes calldata)
    {
        return msg.data;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}
