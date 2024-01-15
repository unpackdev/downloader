//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./Initializable.sol";
import "./IERC20Upgradeable.sol";
import "./ECDSAUpgradeable.sol";

contract MotivCourses is
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ERC721URIStorageUpgradeable
{
    uint256 public constant BASE_DENOMINATOR = 10_000;
    address public operator;
    address public treasuryContract;
    string public baseURI;
    uint256 public totalItems;
    uint256 public platformFee;

    mapping(uint256 => string) public tokenURIs;
    mapping(address => bool) public allowPayment;
    mapping(uint256 => mapping(string => mapping(uint256 => bool)))
        public isPurchased;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => bool)))
        public isExecuted;

    event BaseURIChanged(string newBaseURI);

    event OperatorAddressChanged(address indexed operator);

    event TreasuryAddressChanged(address indexed treasuryAddress);

    event AllowPaymentChanged(address indexed tokenAddress, bool status);

    event PlatformFeeChanged(uint256 _platformFee);

    event CoursePurchased(
        address indexed buyer,
        address indexed receiveAddress,
        address indexed paymentToken,
        uint256 userId,
        string orderNumber,
        uint256 price,
        string sayToTeacher,
        string sayToOwner,
        string buyerTel,
        uint256 nonce
    );

    event ClaimReward(
        uint256 indexed tokenId,
        uint256 indexed courseId,
        uint256 indexed userId,
        address owner,
        uint256 nonce
    );

    function initialize(
        string memory _name,
        string memory _symbol,
        address _operator,
        address _treasuryContract,
        uint256 _platformFee
    ) public initializer {
        ERC721Upgradeable.__ERC721_init_unchained(_name, _symbol);
        PausableUpgradeable.__Pausable_init();
        OwnableUpgradeable.__Ownable_init();
        operator = _operator;
        treasuryContract = _treasuryContract;
        platformFee = _platformFee;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
        emit BaseURIChanged(_newBaseURI);
    }

    function setOperator(address _operator) external onlyOwner {
        require(_operator != operator, "Address set for same operator");
        operator = _operator;
        emit OperatorAddressChanged(_operator);
    }

    function setTreasury(address _treasuryContract) external onlyOwner {
        require(
            _treasuryContract != treasuryContract,
            "Address set for same contract"
        );
        treasuryContract = _treasuryContract;
        emit TreasuryAddressChanged(_treasuryContract);
    }

    function setPlatformFee(uint256 _platformFee) external onlyOwner {
        require(_platformFee <= BASE_DENOMINATOR, "Invalid platform fee");
        platformFee = _platformFee;
        emit PlatformFeeChanged(_platformFee);
    }

    function setAllowPayment(address _token, bool _status) external onlyOwner {
        require(allowPayment[_token] != _status, "This status already set");
        allowPayment[_token] = _status;
        emit AllowPaymentChanged(_token, _status);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        _requireMinted(_tokenId);
        return string(abi.encodePacked(_baseURI(), tokenURIs[_tokenId]));
    }

    function purchaseCourse(
        address _paymentToken,
        address _receiveAddress,
        uint256 _amount,
        uint256 _userId,
        string memory _orderNumber,
        string memory _sayToTeacher,
        string memory _sayToOwner,
        string memory _buyerTel,
        bytes memory _signature,
        uint256 _nonce
    ) external payable whenNotPaused {
        require(!isPurchased[_userId][_orderNumber][_nonce], "Nonce used");
        require(
            allowPayment[_paymentToken] == true,
            "Payment token not supported"
        );
        bytes32 ethSignedMessageHash = ECDSAUpgradeable.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    _userId,
                    _orderNumber,
                    operator,
                    _amount,
                    _sayToTeacher,
                    _sayToOwner,
                    _buyerTel,
                    _nonce
                )
            )
        );

        require(
            operator ==
                ECDSAUpgradeable.recover(ethSignedMessageHash, _signature),
            "Invalid signature"
        );
        uint256 _totalEarnings = _amount;

        isPurchased[_userId][_orderNumber][_nonce] = true;

        if (_paymentToken == address(0)) {
            require(msg.value == _amount, "Invalid ETH value");
            if (platformFee > 0) {
                _totalEarnings =
                    (_amount * (BASE_DENOMINATOR - platformFee)) /
                    BASE_DENOMINATOR;
                (bool sentToTreasury, ) = treasuryContract.call{
                    value: (_amount * platformFee) / BASE_DENOMINATOR
                }("");
                require(sentToTreasury, "FAILED_ETH_TRANSFER");
            }

            (bool sent, ) = _receiveAddress.call{value: (_totalEarnings)}("");
            require(sent, "FAILED_ETH_TRANSFER");
        } else {
            if (platformFee > 0) {
                _totalEarnings =
                    (_amount * (BASE_DENOMINATOR - platformFee)) /
                    BASE_DENOMINATOR;
                IERC20Upgradeable(_paymentToken).transferFrom(
                    msg.sender,
                    treasuryContract,
                    (_amount * platformFee) / BASE_DENOMINATOR
                );
            }

            IERC20Upgradeable(_paymentToken).transferFrom(
                msg.sender,
                _receiveAddress,
                _totalEarnings
            );
        }

        emit CoursePurchased(
            msg.sender,
            _receiveAddress,
            _paymentToken,
            _userId,
            _orderNumber,
            _amount,
            _sayToTeacher,
            _sayToOwner,
            _buyerTel,
            _nonce
        );
    }

    function claimReward(
        string calldata _tokenURI,
        uint256 _tokenId,
        uint256 _userId,
        uint256 _courseId,
        uint256 _nonce,
        bytes memory _signature
    ) external whenNotPaused {
        require(!isExecuted[_userId][_courseId][_nonce], "Nonce used");
        bytes32 ethSignedMessageHash = ECDSAUpgradeable.toEthSignedMessageHash(
            keccak256(abi.encodePacked(_userId, _courseId, operator, _nonce))
        );
        require(
            operator ==
                ECDSAUpgradeable.recover(ethSignedMessageHash, _signature),
            "Invalid signature"
        );
        isExecuted[_userId][_courseId][_nonce] = true;
        totalItems++;
        _mint(msg.sender, _tokenId);
        tokenURIs[_tokenId] = _tokenURI;
        emit ClaimReward(_tokenId, _courseId, _userId, msg.sender, _nonce);
    }

    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _burn(uint256 _tokenId)
        internal
        virtual
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(_tokenId);
    }
}
