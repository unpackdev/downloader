// SPDX-License-Identifier: None
pragma solidity 0.8.11;

// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMWX0kdollllodxkO0XNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMWXOo:'..        ....';ld0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMW0c..                          .:kNMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMXo.                               .c0WMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMW0:..                                .'dNMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMXd:::;,..                              .lXMMMMMMMMMWWMMMMMMMMMMMM
// MMMMMMMMMMMMMMXl'...';:::,.                            .cKMMMMMMKo:cOWMMMMMMMMMM
// MMMMMMMMMMMMMWx.       .':c;.                           .cKMMMMK:.  'kWMMMMMMMMM
// MMMMMMMMMMMMMXc.         ..;c;..                         .lXMMWd.   .cXMMMMMMMMM
// MMMMMMMMMMMMMX:.            .;c;..                        .oNMWo.    ;KMMMMMMMMM
// MMMMMMMMMMMMM0;              ..:c;.                        .cOKo.    .lNMMMMMMMM
// MMMMMMMMMMMMM0,                 .;c;..                      ......,lcckWMMMMMMMM
// MMMMMMMMMMMMMXc.                  .,::;'...                     .lKWWMMMMMMMMMMM
// MMMMMMMMMMMMMW0c,..                 ..,;:::;;;,'..........',;:ldONMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWNKd,.                    ...',;;;;;;;;;;;;;cdOXWMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMXxc'.                          .......;oONMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMWKxl;...                    ...,:okKWMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMNXOxolc:;,'''''''',;;:loxkKNWMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNNXXXXXXXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMWXOolcclokKWW0dddxx0WW0dddddxONW0xdddONMMWKxolccccloxKMMMMMMMMMMMM
// MMMMMMMMMMMMMXd'        'OWo     ,K0'      .k0,    :XMKc.          cNMMMMMMMMMMM
// MMMMMMMMMMMMXc      .loldKMO.    .do.       lo.   .dWNl       .:c::xWMMMMMMMMMMM
// MMMMMMMMMMMWd.     .kMMMMMMX:     ,'        ''    ,KMWo       'cx0NMMMMMMMMMMMMM
// MMMMMMMMMMMNl      ,0MMMMMMWx.        ..         .oWMMXd,.       .:0MMMMMMMMMMMM
// MMMMMMMMMMMWo      .dNN00WMMK,        c:.        ,KMMXxxko;.       lNMMMMMMMMMMM
// MMMMMMMMMMMMK;      ....;KMMWo       .Ok:.       oWMM0,  ..       .kWMMMMMMMMMMM
// MMMMMMMMMMMMMXo,.     .'dNMMM0:......lNXOl......:KMMMWx,.      .'l0WMMMMMMMMMMMM
// MMMMMMMMMMMMMMMNKOkkkOKNMMMMMWNXKKKKXNMMWNXXXXXXNMMMMMMNK0kkkkOKNMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

import "./Ownable.sol";
import "./Address.sol";
import "./ECDSA.sol";
import "./SafeCast.sol";
import "./ERC721.sol";
import "./SutterTreasury.sol";

struct PresaleConfig {
    uint32 startTime;
    uint32 endTime;
    uint256 price;
}

struct PublicConfig {
    bool isDutchAuction;
    uint32 startTime;
    uint32 endTime;
    uint32 stepInterval;
    uint256 price;
    uint256 dutchStartPrice;
    uint256 priceStep;
}

contract CryptoWhaleSquad is Ownable, ERC721, SutterTreasury {
    using Address for address;
    using SafeCast for uint256;
    using ECDSA for bytes32;

    string public baseURI;
    address public whitelistSigner;
    uint256 public totalSupply = 0;
    uint256 public constant supply = 10000;
    uint256 public whitelistLimit = 3000;
    uint256 public constant mintLimit = 8;

    PresaleConfig public presaleConfig;
    PublicConfig public publicConfig;

    bytes32 private DOMAIN_SEPARATOR;
    bytes32 private constant TYPEHASH =
        keccak256("presale(address mintAccount)");

    address[] private mintPayees = [
        0xA7982092BFe8F23871591ca42E709Dd41D6D2587, // Investor
        0x44F9e0C8D55dC016504f808Cd0D7C76E38E9D934, // SubmarineLabs
        0x3b118CABB9cE5A217772fc271357bAb938521901 // Fee
    ];
    uint256[] private mintShares = [66, 33, 1];

    constructor(string memory initialBaseUri)
        ERC721("CryptoWhaleSquad", "CWS")
        SutterTreasury(mintPayees, mintShares)
    {
        baseURI = initialBaseUri;

        presaleConfig = PresaleConfig({
            startTime: 1647561600, // Fri Mar 18 2022 00:00:00 GMT+0000
            endTime: 1647648000, // Sat Mar 19 2022 00:00:00 GMT+0000
            price: 0.08 ether
        });

        publicConfig = PublicConfig({
            isDutchAuction: true,
            startTime: 1647734400, // Sun Mar 20 2022 00:00:00 GMT+0000
            endTime: 1647907200, // Tue Mar 22 2022 00:00:00 GMT+0000
            stepInterval: 1200, // 20 min
            price: 0.1 ether,
            dutchStartPrice: 1 ether,
            priceStep: 0.1 ether
        });

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("CryptoWhaleSquad")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(address to, uint256 mintAmount) private {
        uint256 currentSupply = totalSupply;

        for (uint256 i = 0; i < mintAmount; i++) {
            currentSupply += 1;
            _safeMint(to, currentSupply);
        }

        totalSupply = currentSupply;
    }

    function buyPresale(bytes calldata signature, uint256 mintAmount)
        external
        payable
    {
        PresaleConfig memory _config = presaleConfig;
        uint256 ownerTokenCount = balanceOf(msg.sender);

        require(
            (!msg.sender.isContract() && msg.sender == tx.origin),
            "Contract buys not allowed"
        );
        require(
            block.timestamp >= _config.startTime &&
                block.timestamp < _config.endTime,
            "Presale is not active"
        );
        require(
            (totalSupply + mintAmount) <= whitelistLimit,
            "Not enough CWS remaining"
        );
        require(mintAmount > 0, "Not enough Mint Amount");
        require(mintAmount <= mintLimit, "Mint Amount is too high");
        require(
            (mintAmount + ownerTokenCount) <= mintLimit,
            "You have reached the limit"
        );
        require(
            msg.value == (_config.price * mintAmount),
            "Insufficient payment"
        );
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(TYPEHASH, msg.sender))
            )
        );
        address signer = digest.recover(signature);
        require(
            signer != address(0) && signer == whitelistSigner,
            "Invalid signature"
        );

        mint(msg.sender, mintAmount);
    }

    function buyPublic(uint256 mintAmount) external payable {
        PublicConfig memory _config = publicConfig;
        uint256 ownerTokenCount = balanceOf(msg.sender);

        require(
            (!msg.sender.isContract() && msg.sender == tx.origin),
            "Contract buys not allowed"
        );
        require(
            block.timestamp >= _config.startTime &&
                block.timestamp < _config.endTime,
            "PublicSale is not active"
        );
        require(
            (totalSupply + mintAmount) <= supply,
            "Not enough CWS remaining"
        );
        require(mintAmount > 0, "Not enough Mint Amount");
        require(mintAmount <= mintLimit, "Mint Amount is too high");
        require(
            (mintAmount + ownerTokenCount) <= mintLimit,
            "You have reached the limit"
        );

        uint256 mintPrice = getCurrentAuctionPrice() * mintAmount;
        require(msg.value >= mintPrice, "Insufficient payment");

        if (msg.value > mintPrice) {
            Address.sendValue(payable(msg.sender), msg.value - mintPrice);
        }

        mint(msg.sender, mintAmount);
    }

    function getCurrentAuctionPrice()
        public
        view
        returns (uint256 currentPrice)
    {
        PublicConfig memory _config = publicConfig;

        uint256 timestamp = block.timestamp;

        if (_config.isDutchAuction == false) {
            currentPrice = _config.price;
        } else if (timestamp < _config.startTime) {
            currentPrice = _config.dutchStartPrice;
        } else {
            uint256 elapsedIntervals = (timestamp - _config.startTime) /
                _config.stepInterval;
            uint256 currentStep = (elapsedIntervals * _config.priceStep);

            if (currentStep > _config.dutchStartPrice) {
                currentPrice = _config.price;
            } else {
                currentPrice = _config.dutchStartPrice - currentStep;
            }
        }

        return currentPrice;
    }

    function reserve(address to, uint256 mintAmount) external onlyOwner {
        require(mintAmount > 0, "Not enough Mint Amount");
        mint(to, mintAmount);
    }

    function setPresaleConfig(
        uint256 startTime,
        uint256 endTime,
        uint256 price
    ) external onlyOwner {
        uint32 _startTime = startTime.toUint32();
        uint32 _endTime = endTime.toUint32();

        require(0 < _startTime, "Invalid time");
        require(_startTime < _endTime, "Invalid time");

        presaleConfig.startTime = _startTime;
        presaleConfig.endTime = _endTime;
        presaleConfig.price = price;
    }

    function setDutchAuctionConfig(
        bool isDutchAuction,
        uint256 startTime,
        uint256 endTime,
        uint256 stepInterval,
        uint256 price,
        uint256 dutchStartPrice,
        uint256 priceStep
    ) external onlyOwner {
        uint32 _startTime = startTime.toUint32();
        uint32 _endTime = endTime.toUint32();
        uint32 _stepInterval = stepInterval.toUint32();

        require(0 < _startTime, "Invalid time");
        require(_startTime < _endTime, "Invalid time");
        require(0 < stepInterval, "0 step interval");
        require(
            0 < price && 0 < priceStep && priceStep < dutchStartPrice,
            "Invalid price step"
        );

        publicConfig.isDutchAuction = isDutchAuction;
        publicConfig.startTime = _startTime;
        publicConfig.endTime = _endTime;
        publicConfig.stepInterval = _stepInterval;
        publicConfig.price = price;
        publicConfig.dutchStartPrice = dutchStartPrice;
        publicConfig.priceStep = priceStep;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setWhitelistSigner(address newWhitelistSigner) external onlyOwner {
        whitelistSigner = newWhitelistSigner;
    }
}
