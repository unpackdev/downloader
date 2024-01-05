// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./IERC20Short.sol";
import "./Adminable.sol";
import "./NetworksPreset.sol";
import "./TokensPreset.sol";

contract CosmoFundErc20CrossChainSwap is
    Ownable,
    Adminable,
    Pausable,
    NetworksPreset,
    TokensPreset
{
    using SafeMath for uint256;
    bool public mintAndBurn;

    // swaps
    struct SwapInfo {
        bool enabled;
        uint256 received;
        uint256 sent;
    }
    mapping(uint256 => mapping(address => SwapInfo)) public swapInfo;

    // events
    event Swap(
        uint256 indexed netId,
        address indexed token,
        address indexed to,
        uint256 amount
    );
    event Withdrawn(
        uint256 indexed netId,
        address indexed token,
        address indexed to,
        uint256 amount
    );

    constructor(uint256 _networkThis, bool _mintAndBurn) {
        setup();
        networkThis = _networkThis;
        mintAndBurn = _mintAndBurn;
    }

    function setup() private {
        _addNetwork("Ethereum Mainnet");
        _addNetwork("Binance Smart Chain Mainnet");

        _addToken(
            0x27cd7375478F189bdcF55616b088BE03d9c4339c, // Ethereum Mainnet
            //0x60E5FfdE4230985757E5Dd486e33E85AfEfC557b, // BSC Mainnet
            "Cosmo Token (COSMO)"
        );
        _addToken(
            0xB9FDc13F7f747bAEdCc356e9Da13Ab883fFa719B, // Ethereum Mainnet
            //0x7A43397662e82a9C15D590f211347D2871B12bb7, // BSC Mainnet
            "CosmoMasks Power (CMP)"
        );
    }

    function swap(
        uint256 netId,
        address token,
        uint256 amount
    ) public whenNotPaused {
        swapCheckStatus(netId, token);

        address to = _msgSender();
        IERC20Short(token).transferFrom(to, address(this), amount);

        tokenInfo[token].received = tokenInfo[token].received.add(amount);
        swapInfo[netId][token].received = swapInfo[netId][token].received.add(
            amount
        );

        if (mintAndBurn) {
            IERC20Short(token).burn(amount);
        }

        emit Swap(netId, token, to, amount);
    }

    function swapFrom(
        uint256 netId,
        address token,
        address from,
        uint256 amount
    ) public whenNotPaused {
        swapCheckStatus(netId, token);

        address to = from;
        IERC20Short(token).transferFrom(to, address(this), amount);

        tokenInfo[token].received = tokenInfo[token].received.add(amount);
        swapInfo[netId][token].received = swapInfo[netId][token].received.add(
            amount
        );

        if (mintAndBurn) {
            IERC20Short(token).burn(amount);
        }

        emit Swap(netId, token, to, amount);
    }

    function swapWithPermit(
        uint256 netId,
        address token,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        swapCheckStatus(netId, token);

        address to = _msgSender();
        IERC20Short(token).permit(to, address(this), amount, deadline, v, r, s);
        IERC20Short(token).transferFrom(to, address(this), amount);

        tokenInfo[token].received = tokenInfo[token].received.add(amount);
        swapInfo[netId][token].received = swapInfo[netId][token].received.add(
            amount
        );

        if (mintAndBurn) {
            IERC20Short(token).burn(amount);
        }

        emit Swap(netId, token, to, amount);
    }

    function withdraw(
        uint256 netId,
        address token,
        address to,
        uint256 amount
    ) public onlyAdmin {
        if (mintAndBurn) {
            IERC20Short(token).mint(address(this), amount);
        }
        IERC20Short(token).transfer(to, amount);

        tokenInfo[token].sent = tokenInfo[token].sent.add(amount);
        swapInfo[netId][token].sent = swapInfo[netId][token].sent.add(amount);

        emit Withdrawn(netId, token, to, amount);
    }

    // networks
    function addNetwork(string memory description) public onlyOwner {
        _addNetwork(description);
    }

    function setNetworkStatus(uint256 netId, bool status) public onlyOwner {
        _setNetworkStatus(netId, status);
    }

    //  Tokens
    function addToken(address token, string memory description)
        public
        onlyOwner
    {
        _addToken(token, description);
    }

    function setTokenStatus(address token, bool status) public onlyOwner {
        _setTokenStatus(token, status);
    }

    // swaps
    function setSwapStatus(
        uint256 netId,
        address token,
        bool status
    ) public onlyOwner returns (bool) {
        return swapInfo[netId][token].enabled = status;
    }

    // get token swap status
    function isSwapEnabled(uint256 netId, address token)
        public
        view
        returns (bool)
    {
        return swapInfo[netId][token].enabled;
    }

    // get token swap status
    function swapStatus(uint256 netId, address token)
        public
        view
        returns (bool)
    {
        if (paused()) return false;
        if (!isNetworkEnabled(netId)) return false;
        if (!isTokenEnabled(token)) return false;
        if (!isSwapEnabled(netId, token)) return false;
        return true;
    }

    function swapCheckStatus(uint256 netId, address token)
        public
        view
        returns (bool)
    {
        require(
            netId != networkThis,
            "Swap inside the same network is impossible"
        );
        require(
            isNetworkEnabled(netId),
            "Swap is not enabled for this network"
        );
        require(isTokenEnabled(token), "Swap is not enabled for this token");
        require(
            isSwapEnabled(netId, token),
            "Swap of this token for this network not enabled"
        );
        return true;
    }

    // pause all swaps
    function pause() public onlyOwner {
        _pause();
    }

    // unpause all swaps
    function unpause() public onlyOwner {
        _unpause();
    }

    function withdrawUnaccountedTokens(address token) public onlyOwner {
        uint256 unaccounted;
        if (mintAndBurn) unaccounted = tokenBalance(token);
        else unaccounted = tokensUnaccounted(token);
        IERC20Short(token).transfer(_msgSender(), unaccounted);
    }

    function transferAdminship(address newAdmin) public virtual onlyOwner {
        _transferAdminship(newAdmin);
    }
}
