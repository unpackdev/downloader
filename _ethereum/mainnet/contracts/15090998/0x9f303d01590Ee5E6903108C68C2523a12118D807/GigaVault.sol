// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./SafeMath.sol";
import "./ECDSA.sol";
import "./IERC721.sol";

import "./GatewayStorage.sol";
import "./Validator.sol";

contract GigaVault is MainchainGatewayStorage {
    using SafeMath for uint256;

    bool private _initialized;

    constructor() {
        pause();
        _initialized = true;
    }

    function initialized() public view virtual returns (bool) {
        return _initialized;
    }

    function initialize() public {
        require(!_initialized, "Contract can be initialized only once");
        _setOwner(_msgSender());
        _initialized = true;
    }

    modifier onlyMappedToken(address _token) {
        require(
            registry.isTokenMapped(_token, 721),
            "GigaVault: Token is not mapped"
        );
        _;
    }

    modifier onlyNewWithdrawal(uint256 _withdrawalId) {
        WithdrawalEntry storage _entry = withdrawals[_withdrawalId];
        require(
            _entry.owner == address(0) && _entry.tokenAddress == address(0), "Tx already processed"
        );
        _;
    }

    function depositERC721For(
        string memory _user,
        address _token,
        uint256 _tokenId
    ) public whenNotPaused returns (uint256) {
        IERC721(_token).transferFrom(msg.sender, address(this), _tokenId);
        return _createDepositEntry(msg.sender, _user, _token, _tokenId);
    }

    function withdrawERC721For(
        uint256 _withdrawalId,
        address _user,
        address _token,
        uint256 _tokenId,
        bytes calldata _signatures
    ) public whenNotPaused onlyMappedToken(_token) {
        bytes32 _hash = keccak256(
            abi.encodePacked(
                "withdrawERC721",
                _withdrawalId,
                _user,
                _token,
                _tokenId
            )
        );

        require(verifySignatures(_hash, _signatures), "Invalid signatures");

        require(
            _tryERC721TransferFrom(_token, address(this), _user, _tokenId),
            "GigaVault: Could not withdraw token!"
        );

        // if (!_tryERC721TransferFrom(_token, address(this), _user, _tokenId)) {

        // require(
        //     IERC721Mintable(_token).mint(_user, _tokenId),
        //     "GigaVault: Minting ERC721 token to gateway failed"
        // );
        // }s

        _insertWithdrawalEntry(_withdrawalId, _user, _token, _tokenId);
    }

    function verifySignatures(bytes32 _hash, bytes calldata _signatures)
        public
        view
        returns (bool)
    {
        uint256 _signatureCount = _signatures.length.div(65);

        Validator _validator = Validator(
            registry.getContract(registry.VALIDATOR())
        );

        uint256 _validatorCount = 0;
        address _lastSigner = address(0);

        for (uint256 i = 0; i < _signatureCount; i++) {
            address _signer = ECDSA.recover(
                _hash,
                _signatures[i * 65:i * 65 + 65]
            );

            if (_validator.isValidator(_signer)) {
                _validatorCount++;
            }
            // Prevent duplication of signatures
            require(_signer > _lastSigner);
            _lastSigner = _signer;
        }

        return _validator.checkThreshold(_validatorCount);
    }

    function _createDepositEntry(
        address _sender,
        string memory _owner,
        address _token,
        uint256 _number
    ) internal onlyMappedToken(_token) returns (uint256 _depositId) {
        // string storage _sidechainToken = mainchainMap[_token];

        (, string memory _sidechainToken, uint32 _tokenStandard) = registry
            .getMappedToken(_token);

        DepositEntry memory _entry = DepositEntry(
            _owner,
            _token,
            _sidechainToken,
            _number
        );

        deposits.push(_entry);
        _depositId = depositCount++;

        emit TokenDeposited(
            _depositId,
            _sender,
            _owner,
            _token,
            _sidechainToken,
            _number
        );
    }

    function _insertWithdrawalEntry(
        uint256 _withdrawalId,
        address _owner,
        address _token,
        uint256 _number
    ) internal onlyNewWithdrawal(_withdrawalId) {
        WithdrawalEntry memory _entry = WithdrawalEntry(
            _owner,
            _token,
            _number
        );

        withdrawals[_withdrawalId] = _entry;

        emit TokenWithdrew(_withdrawalId, _owner, _token, _number);
    }

    // See more here https://blog.polymath.network/try-catch-in-solidity-handling-the-revert-exception-f53718f76047
    function _tryERC721TransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _tokenId
    ) internal returns (bool) {
        (bool success, ) = _token.call(
            abi.encodeWithSelector(
                IERC721(_token).transferFrom.selector,
                _from,
                _to,
                _tokenId
            )
        );
        return success;
    }
}
