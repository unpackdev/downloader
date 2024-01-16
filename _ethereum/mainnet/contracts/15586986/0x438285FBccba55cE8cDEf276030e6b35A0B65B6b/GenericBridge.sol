pragma solidity ^0.8.0;
import "./ERC20BurnableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./BlackholePreventionUpgrade.sol";
import "./DTOBridgeToken.sol";
import "./IDTOTokenBridge.sol";
import "./Governable.sol";
import "./ChainIdHolding.sol";
import "./DTOUpgradeableBase.sol";

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./AddressUpgradeable.sol";

contract GenericBridge is
    DTOUpgradeableBase,
    ReentrancyGuardUpgradeable,
    BlackholePreventionUpgrade,
    Governable,
    ChainIdHolding
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address payable;
    struct TokenInfo {
        address addr;
        uint256 chainId;
    }

    address public NATIVE_TOKEN_ADDRESS;
    mapping(bytes32 => bool) public alreadyClaims;
    address[] public bridgeApprovers;
    mapping(address => bool) public approverMap; //easily check approver signature
    mapping(uint256 => bool) public supportedChainIds;
    mapping(address => uint256[]) public tokenMapList; //to which chain ids this token is bridged to
    mapping(address => mapping(uint256 => bool)) public tokenMapSupportCheck; //to which chain ids this token is bridged to
    mapping(uint256 => mapping(address => address)) public tokenMap; //chainid => origin token => bridge token
    mapping(address => TokenInfo) public tokenMapReverse; //bridge token => chain id => origin token
    mapping(address => bool) public bridgeTokens; //mapping of bridge tokens on this chain
    uint256 public claimFee; //fee paid in native token for nodes maintenance

    uint256 public index;
    uint256 public minApprovers;
    address payable public feeReceiver;
    mapping(uint256 => mapping(address => uint256)) public feeForTokens;
    uint256 public defaultFeePercentage;
    uint256 public constant DEFAULT_FEE_DIVISOR = 10_000;
    uint256 public constant DEFAULT_FEE_PERCENTAGE = 10; //0.1%

    //_token is the origin token, regardless it's bridging from or to the origini token
    event RequestBridge(
        address indexed _token,
        bytes _toAddr,
        uint256 _amount,
        uint256 _originChainId,
        uint256 _fromChainId,
        uint256 _toChainId,
        uint256 _index
    );
    event ClaimToken(
        address indexed _token,
        address indexed _toAddr,
        uint256 _amount,
        uint256 _originChainId,
        uint256 _fromChainId,
        uint256 _toChainId,
        uint256 _index,
        bytes32 _claimId
    );
    event ValidatorSign(
        address _validator,
        bytes32 _claimId,
        uint256 _timestamp
    );

    event SetFeeToken(
        uint256 chainId,
        address token,
        uint256 fee,
        uint256 timestamp
    );

    function initialize(uint256[] memory _chainIds) public initializer {
        __DTOUpgradeableBase_initialize();
        __Governable_initialize();
        __ChainIdHolding_init();
        NATIVE_TOKEN_ADDRESS = 0x1111111111111111111111111111111111111111;
        supportedChainIds[chainId] = true;
        minApprovers = 2;
        claimFee = 0;
        governance = owner();

        for (uint256 i = 0; i < _chainIds.length; i++) {
            supportedChainIds[_chainIds[i]] = true;
        }
        defaultFeePercentage = DEFAULT_FEE_PERCENTAGE; //0.1 %
    }

    function setMinApprovers(uint256 _val) public onlyGovernance {
        require(_val >= 2, "!min set approver");
        minApprovers = _val;
    }

    function setFeeReceiver(address payable _feeReceiver)
        external
        onlyGovernance
    {
        feeReceiver = _feeReceiver;
    }

    //originTokens for this chain
    function setFeeForTokens(
        uint256[] memory chainIds,
        address[] memory originTokens,
        uint256[] memory fees
    ) external onlyGovernance {
        require(
            chainIds.length == originTokens.length &&
                originTokens.length == fees.length,
            "!input"
        );
        for (uint256 i = 0; i < originTokens.length; i++) {
            feeForTokens[chainIds[i]][originTokens[i]] = fees[i];
            emit SetFeeToken(
                chainIds[i],
                originTokens[i],
                fees[i],
                block.timestamp
            );
        }
    }

    function setDefaultFeePercentage(uint256 _val) external onlyGovernance {
        defaultFeePercentage = _val;
    }

    function addApprover(address _addr) public onlyGovernance {
        require(!approverMap[_addr], "already approver");
        require(_addr != address(0), "non zero address");
        bridgeApprovers.push(_addr);
        approverMap[_addr] = true;
    }

    function addApprovers(address[] memory _addrs) public onlyGovernance {
        for (uint256 i = 0; i < _addrs.length; i++) {
            if (!approverMap[_addrs[i]]) {
                bridgeApprovers.push(_addrs[i]);
                approverMap[_addrs[i]] = true;
            }
        }
    }

    function removeApprover(address _addr) public onlyGovernance {
        require(approverMap[_addr], "not approver");
        for (uint256 i = 0; i < bridgeApprovers.length; i++) {
            if (bridgeApprovers[i] == _addr) {
                bridgeApprovers[i] = bridgeApprovers[
                    bridgeApprovers.length - 1
                ];
                bridgeApprovers.pop();
                approverMap[_addr] = false;
                return;
            }
        }
    }

    function setSupportedChainId(uint256 _chainId, bool _val)
        public
        onlyGovernance
    {
        supportedChainIds[_chainId] = _val;
    }

    function setSupportedChainIds(uint256[] memory _chainIds, bool _val)
        public
        onlyGovernance
    {
        for (uint256 i = 0; i < _chainIds.length; i++) {
            supportedChainIds[_chainIds[i]] = _val;
        }
    }

    function setGovernanceFee(uint256 _fee) public onlyGovernance {
        claimFee = _fee;
    }

    function requestBridge(
        address _tokenAddress,
        bytes memory _toAddr,
        uint256 _amount,
        uint256 _toChainId
    ) public payable nonReentrant {
        require(
            chainId != _toChainId,
            "source and target chain ids must be different"
        );
        require(supportedChainIds[_toChainId], "unsupported chainId");
        if (!isBridgeToken(_tokenAddress)) {
            //transfer and lock token here
            // require(
            //     _amount > feeForTokens[chainId][_tokenAddress],
            //     "amount too small"
            // );

            uint256 feePercent = defaultFeePercentage == 0
                ? DEFAULT_FEE_PERCENTAGE
                : defaultFeePercentage;
            uint256 forUser =
                (_amount * (DEFAULT_FEE_DIVISOR - feePercent)) /
                DEFAULT_FEE_DIVISOR;
            uint256 forFee = _amount - forUser;

            safeTransferIn(_tokenAddress, msg.sender, _amount);
            safeTransferOut(_tokenAddress, msg.sender, 0, forFee);

            emit RequestBridge(
                _tokenAddress,
                _toAddr,
                forUser,
                chainId,
                chainId,
                _toChainId,
                index
            );
            index++;

            if (!tokenMapSupportCheck[_tokenAddress][_toChainId]) {
                tokenMapList[_tokenAddress].push(_toChainId);
                tokenMapSupportCheck[_tokenAddress][_toChainId] = true;
            }
        } else {
            //uint256 _originChainId = tokenMapReverse[_tokenAddress].chainId;
            address _originToken = tokenMapReverse[_tokenAddress].addr;
            // require(
            //     _amount > feeForTokens[_originChainId][_originToken],
            //     "amount too small"
            // );
            ERC20BurnableUpgradeable(_tokenAddress).burnFrom(
                msg.sender,
                _amount
            );
            emit RequestBridge(
                _originToken,
                _toAddr,
                _amount,
                tokenMapReverse[_tokenAddress].chainId,
                chainId,
                _toChainId,
                index
            );
            index++;
        }
    }

    function verifySignatures(
        bytes32[] memory r,
        bytes32[] memory s,
        uint8[] memory v,
        bytes32 signedData
    ) internal returns (bool) {
        require(minApprovers >= 2, "!min approvers");
        require(bridgeApprovers.length >= minApprovers, "!min approvers");
        address[] memory uniqueSigners = new address[](r.length);
        uint256 successSigner = 0;
        if (
            r.length == s.length &&
            s.length == v.length &&
            v.length >= minApprovers
        ) {
            for (uint256 i = 0; i < r.length; i++) {
                address signer = ecrecover(
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n32",
                            signedData
                        )
                    ),
                    v[i],
                    r[i],
                    s[i]
                );
                if (approverMap[signer]) {
                    bool signerIsGood = true;
                    for (uint256 k = 0; k < successSigner; k++) {
                        if (uniqueSigners[k] == signer) {
                            signerIsGood = false;
                            break;
                        }
                    }
                    if (signerIsGood) {
                        uniqueSigners[successSigner] = signer;
                        successSigner++;
                    }
                    emit ValidatorSign(signer, signedData, block.timestamp);
                }
            }
        }

        return successSigner >= minApprovers;
    }

    //@dev: _claimData: includex tx hash, event index, event data
    //@dev _tokenInfos: contain token name and symbol of bridge token
    //_chainIdsIndex: length = 4, _chainIdsIndex[0] = originChainId, _chainIdsIndex[1] => fromChainId, _chainIdsIndex[2] = toChainId = this chainId, _chainIdsIndex[3] = index
    function claimToken(
        address _originToken,
        address _toAddr,
        uint256 _amount,
        uint256[] memory _chainIdsIndex,
        bytes32 _txHash,
        bytes32[] memory r,
        bytes32[] memory s,
        uint8[] memory v,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external payable nonReentrant {
        require(
            _chainIdsIndex.length == 4 && chainId == _chainIdsIndex[2],
            "!chain id claim"
        );
        bytes32 _claimId = keccak256(
            abi.encode(
                _originToken,
                _toAddr,
                _amount,
                _chainIdsIndex,
                _txHash,
                _name,
                _symbol,
                _decimals
            )
        );
        require(!alreadyClaims[_claimId], "already claim");
        alreadyClaims[_claimId] = true;
        require(verifySignatures(r, s, v, _claimId), "invalid signatures");

        payClaimFee(msg.value);

        // alreadyClaims[_claimId] = true;

        if (_originToken == NATIVE_TOKEN_ADDRESS) {
            if (_chainIdsIndex[0] != chainId) {
                //claim native token from another chain to the current chain
                //check whether wrap token exist
                if (tokenMap[_chainIdsIndex[0]][_originToken] == address(0)) {
                    DTOBridgeToken bt = new DTOBridgeToken();
                    bt.initialize(
                        _originToken,
                        _chainIdsIndex[0],
                        _name,
                        _symbol,
                        _decimals
                    );
                    tokenMap[_chainIdsIndex[0]][_originToken] = address(bt);
                    tokenMapReverse[address(bt)] = TokenInfo({
                        addr: _originToken,
                        chainId: _chainIdsIndex[0]
                    });
                    bridgeTokens[address(bt)] = true;
                }
                _mintTokenForUser(
                    _amount,
                    _originToken,
                    _chainIdsIndex,
                    _txHash,
                    _toAddr
                );
                emit ClaimToken(
                    _originToken,
                    _toAddr,
                    _amount,
                    _chainIdsIndex[0],
                    _chainIdsIndex[1],
                    chainId,
                    _chainIdsIndex[3],
                    _claimId
                );
            } else {
                //claiming original token
                _transferOriginToken(
                    _amount,
                    _originToken,
                    _chainIdsIndex,
                    _toAddr
                );

                emit ClaimToken(
                    _originToken,
                    _toAddr,
                    _amount,
                    _chainIdsIndex[0],
                    _chainIdsIndex[1],
                    chainId,
                    _chainIdsIndex[3],
                    _claimId
                );
            }
        } else if (tokenMapList[_originToken].length == 0) {
            //claiming bridge token
            if (tokenMap[_chainIdsIndex[0]][_originToken] == address(0)) {
                //create bridge token
                DTOBridgeToken bt = new DTOBridgeToken();
                bt.initialize(
                    _originToken,
                    _chainIdsIndex[0],
                    _name,
                    _symbol,
                    _decimals
                );
                tokenMap[_chainIdsIndex[0]][_originToken] = address(bt);
                tokenMapReverse[address(bt)] = TokenInfo({
                    addr: _originToken,
                    chainId: _chainIdsIndex[0]
                });
                bridgeTokens[address(bt)] = true;
            }

            //claim
            _mintTokenForUser(
                _amount,
                _originToken,
                _chainIdsIndex,
                _txHash,
                _toAddr
            );
            emit ClaimToken(
                _originToken,
                _toAddr,
                _amount,
                _chainIdsIndex[0],
                _chainIdsIndex[1],
                chainId,
                _chainIdsIndex[3],
                _claimId
            );
        } else {
            //claiming original token
            _transferOriginToken(
                _amount,
                _originToken,
                _chainIdsIndex,
                _toAddr
            );
            emit ClaimToken(
                _originToken,
                _toAddr,
                _amount,
                _chainIdsIndex[0],
                _chainIdsIndex[1],
                chainId,
                _chainIdsIndex[3],
                _claimId
            );
        }
    }

    function _mintTokenForUser(
        uint256 _amount,
        address _originToken,
        uint256[] memory _chainIdsIndex,
        bytes32 _txHash,
        address _toAddr
    ) internal {
        IDTOTokenBridge(tokenMap[_chainIdsIndex[0]][_originToken])
            .claimBridgeToken(
                _originToken,
                _toAddr,
                _amount,
                _chainIdsIndex,
                _txHash
            );
    }

    function _transferOriginToken(
        uint256 _amount,
        address _originToken,
        uint256[] memory _chainIdsIndex,
        address _toAddr
    ) internal {
        //claiming original token
        (uint256 forUser, uint256 forFee) = getAmountsToSend(
            _amount,
            _originToken,
            _chainIdsIndex[0]
        );
        safeTransferOut(_originToken, _toAddr, forUser, forFee);
    }

    function payClaimFee(uint256 _amount) internal {
        if (claimFee > 0) {
            require(_amount >= claimFee, "!min claim fee");
            payable(governance).sendValue(_amount);
        }
    }

    function isBridgeToken(address _token) public view returns (bool) {
        return bridgeTokens[_token];
    }

    function safeTransferIn(
        address _token,
        address _from,
        uint256 _amount
    ) internal {
        if (_token == NATIVE_TOKEN_ADDRESS) {
            require(msg.value == _amount, "invalid bridge amount");
        } else {
            IERC20Upgradeable erc20 = IERC20Upgradeable(_token);
            uint256 balBefore = erc20.balanceOf(address(this));
            erc20.safeTransferFrom(_from, address(this), _amount);
            require(
                erc20.balanceOf(address(this)).sub(balBefore) == _amount,
                "!transfer from"
            );
        }
    }

    function safeTransferOut(
        address _token,
        address _toAddr,
        uint256 _forUser,
        uint256 _forFee
    ) internal {
        if (_token == NATIVE_TOKEN_ADDRESS) {
            payable(_toAddr).sendValue(_forUser);
            payable(getFeeRecipientAddress()).sendValue(_forFee);
        } else {
            IERC20Upgradeable erc20 = IERC20Upgradeable(_token);
            uint256 balBefore = erc20.balanceOf(address(this));
            if (_forUser > 0) {
                erc20.safeTransfer(_toAddr, _forUser);
            }
            if (_forFee > 0) {
                erc20.safeTransfer(getFeeRecipientAddress(), _forFee);
            }
            require(
                balBefore.sub(erc20.balanceOf(address(this))) ==
                    _forUser + _forFee,
                "!transfer to"
            );
        }
    }

    function getAmountsToSend(
        uint256 amount,
        address originToken,
        uint256 originChainId
    ) internal view returns (uint256 forUser, uint256 forFee) {
        uint256 feePercent = defaultFeePercentage == 0
            ? DEFAULT_FEE_PERCENTAGE
            : defaultFeePercentage;
        forUser =
            (amount * (DEFAULT_FEE_DIVISOR - feePercent)) /
            DEFAULT_FEE_DIVISOR;
        forFee = amount - forUser;
        // if (feeForTokens[originChainId][originToken] == 0) {
        //     forUser =
        //         (amount * (DEFAULT_FEE_DIVISOR - defaultFeePercentage)) /
        //         DEFAULT_FEE_DIVISOR;
        //     forFee = amount - forUser;
        // } else {
        //     if (amount < feeForTokens[originChainId][originToken]) {
        //         forUser = 0;
        //         forFee = amount;
        //     } else {
        //         forUser = amount - feeForTokens[originChainId][originToken];
        //         forFee = feeForTokens[originChainId][originToken];
        //     }
        // }
    }

    function getFeeInfo(address token)
        external
        view
        returns (uint256 feeAmount, uint256 feePercent)
    {
        feePercent = defaultFeePercentage == 0
            ? DEFAULT_FEE_PERCENTAGE
            : defaultFeePercentage;
        // if (!isBridgeToken(token)) {
        //     //token on this chain
        //     feeAmount = feeForTokens[chainId][token];
        //     feePercent = defaultFeePercentage;
        // } else {
        //     TokenInfo memory tokenInfo = tokenMapReverse[token];
        //     feeAmount = feeForTokens[tokenInfo.chainId][tokenInfo.addr];
        //     feePercent = defaultFeePercentage;
        // }
    }

    function getFeeRecipientAddress()
        internal
        view
        returns (address payable ret)
    {
        ret = feeReceiver == address(0) ? payable(owner()) : feeReceiver;
    }

    function getSupportedChainsForToken(address _token)
        external
        view
        returns (uint256[] memory)
    {
        return tokenMapList[_token];
    }

    function getBridgeApprovers() external view returns (address[] memory) {
        return bridgeApprovers;
    }

    /***********************************|
	|          Only Admin               |
	|      (blackhole prevention)       |
	|__________________________________*/
    // function withdrawEther(address payable receiver, uint256 amount)
    //     external
    //     virtual
    //     onlyGovernance
    // {
    //     _withdrawEther(receiver, amount);
    // }

    // function withdrawERC20(
    //     address payable receiver,
    //     address tokenAddress,
    //     uint256 amount
    // ) external virtual onlyGovernance {
    //     _withdrawERC20(receiver, tokenAddress, amount);
    // }

    // function withdrawERC721(
    //     address payable receiver,
    //     address tokenAddress,
    //     uint256 tokenId
    // ) external virtual onlyGovernance {
    //     _withdrawERC721(receiver, tokenAddress, tokenId);
    // }
}
