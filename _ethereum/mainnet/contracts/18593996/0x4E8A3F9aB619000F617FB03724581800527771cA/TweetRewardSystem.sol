// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;
import "./Ownable.sol";
import "./IERC20.sol";

contract TweetRewardSystem is Ownable {
    uint256 public withdrawCoolDown = 1 hours;
    address public secret;
    bool public useOnlyWhitelistedTokens = false;

    address[] public whiteListedTokens;
    mapping(address => bool) public isTokenWhitelisted;
    mapping(bytes => bool) private usedSignatures;
    mapping(address => uint256) public lastWithdraw;

    event Withdraw(address token, address recipient, uint256 amount);
    event Deposit(address token, uint256 amount, address sender);
    event WithdrawBatch(address[] tokens, address to, uint256[] amounts);
    event TokenAdded(address token);
    event TokenRemoved(address token);

    constructor(address _signer) {
        secret = _signer;
    }

    function setSecret(address _secret) external onlyOwner {
        secret = _secret;
    }

    function toggleUseOnlyWhitelistedTokens() external onlyOwner {
        useOnlyWhitelistedTokens = !useOnlyWhitelistedTokens;
    }

    function isValidToken(address _token) public view returns (bool) {
        if (_token == address(0)) {
            return true;
        }
        return isTokenWhitelisted[_token] || !useOnlyWhitelistedTokens;
    }

    function batchAddWhitelistedTokens(
        address[] calldata _tokens
    ) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            require(!isValidToken(token), "addTokens: Token already exists");
            isTokenWhitelisted[token] = true;
            whiteListedTokens.push(token);
            emit TokenAdded(token);
        }
    }

    function removeToken(address _token, uint256 index) external onlyOwner {
        require(isValidToken(_token), "removeToken: Token not found");
        require(index < whiteListedTokens.length, "removeToken: Invalid index");
        isTokenWhitelisted[_token] = false;
        _removeTokenAtIndex(index);
        emit TokenRemoved(_token);
    }

    function _removeTokenAtIndex(uint256 index) internal {
        if (index < whiteListedTokens.length - 1) {
            whiteListedTokens[index] = whiteListedTokens[
                whiteListedTokens.length - 1
            ];
        }
        whiteListedTokens.pop();
    }

    function getWhiteListedTokens() external view returns (address[] memory) {
        return whiteListedTokens;
    }

    function depositERC20(address _token, uint256 _amount) external {
        require(isValidToken(_token), "Invalid token");
        require(_amount > 0, "depositERC20: Amount must be greater than zero");
        require(
            IERC20(_token).allowance(msg.sender, address(this)) >= _amount,
            "depositERC20: Allowance not sufficient"
        );
        require(
            IERC20(_token).balanceOf(msg.sender) >= _amount,
            "depositERC20: You don't have enough balance"
        );

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        emit Deposit(_token, _amount, msg.sender);
    }

    function depositETH() external payable {
        require(msg.value > 0, "depositETH: Invalid Ether deposit amount");
        emit Deposit(address(0), msg.value, msg.sender);
    }

    function withdraw(
        address _token,
        uint256 _amount,
        uint256 _timeout,
        bytes calldata _signature
    ) external {
        require(_timeout > block.timestamp, "withdraw: Signature is expired");
        require(_amount > 0, "withdraw: Amount must be greater than zero");
        require(
            !usedSignatures[_signature],
            "withdraw: Signature already used"
        );
        require(
            lastWithdraw[msg.sender] + withdrawCoolDown < block.timestamp,
            "withdraw: Withdrawal is too soon"
        );
        require(
            _verifyHashSignature(
                keccak256(abi.encode(msg.sender, _token, _amount, _timeout)),
                _signature
            ),
            "withdraw: Signature is invalid"
        );

        usedSignatures[_signature] = true;
        lastWithdraw[msg.sender] = block.timestamp;

        if (_token == address(0)) {
            payable(msg.sender).transfer(_amount);
        } else {
            IERC20(_token).transfer(msg.sender, _amount);
        }
        emit Withdraw(_token, msg.sender, _amount);
    }

    function withdrawBatch(
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256 _timeout,
        bytes calldata _signature
    ) external {
        require(
            _timeout > block.timestamp,
            "withdrawBatch: Signature is expired"
        );
        require(
            !usedSignatures[_signature],
            "withdrawBatch: Signature already used"
        );
        require(
            lastWithdraw[msg.sender] + withdrawCoolDown < block.timestamp,
            "withdrawBatch: Withdrawal is too soon"
        );
        require(
            _tokens.length == _amounts.length,
            "withdrawBatch: Invalid _tokens or _amounts length"
        );
        require(
            _verifyHashSignature(
                keccak256(abi.encode(msg.sender, _tokens, _amounts, _timeout)),
                _signature
            ),
            "withdrawBatch: Signature is invalid"
        );

        usedSignatures[_signature] = true;
        lastWithdraw[msg.sender] = block.timestamp;

        withdrawAllTokens(_tokens, _amounts);

        emit WithdrawBatch(_tokens, msg.sender, _amounts);
    }

    function withdrawAllTokens(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            uint256 tokenBalance = _amounts[i];
            if (tokenBalance > 0) {
                if (token == address(0)) {
                    payable(msg.sender).transfer(tokenBalance);
                } else {
                    IERC20(token).transfer(msg.sender, tokenBalance);
                }
            }
        }
    }

    function _verifyHashSignature(
        bytes32 freshHash,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return false;
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        address signer = address(0);
        if (v == 27 || v == 28) {
            // solium-disable-next-line arg-overflow
            signer = ecrecover(hash, v, r, s);
        }
        return secret == signer;
    }
}
