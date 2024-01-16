// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.8;

import "./IERC721Enumerable.sol";
import "./Ownable.sol";

import "./ITypeface.sol";

import "./ICapsuleToken.sol";

error InputAddressCanNotBeAddressZero();
error InvalidFontForRenderer(address renderer);
error InvalidRenderer();
error NoGiftAvailable();
error NotSkribbleOwner(address owner);
error NotCapsuleTypeface();
error ValueBelowMintPrice();
error OnlyFeeReceiverOneCanDoThis();
error OnlyFeeReceiverTwoCanDoThis();
error OnlyMintMasterCanDoThis();
error CanOnlySetLowerFeeTakes(uint256 currentFeeTake, uint256 feeTakeInput);


interface ISkribbles {
    event AddValidRenderer(address renderer);
    event MintSkribble(
        uint256 indexed id,
        address indexed to,
        bytes3 indexed color,
        Font font,
        bytes32[8] text
    );
    event MintGift(address minter);
    event SetDefaultRenderer(address renderer);
    event SetFeeReceiverOne(address receiver);
    event SetFeeReceiverTwo(address receiver);
    event SetFeeTakeOne(uint256 newFeeTake);
    event SetMintingPrice(uint256 newMintPrice);
    event SetMetadata(address metadata);
    event SetRoyalty(uint256 royalty);
    event SetSkribbleText(uint256 indexed id, bytes32[8] text);
    event SetSkribbleFont(uint256 indexed id, Font font);
    event SetSkribbleColor(uint256 indexed id, bytes3 color);
    event SetSkribbleRenderer(uint256 indexed id, address renderer);
    event SetMintMaster(address mintMaster);
    event SetContractURI(string contractURI);
    event SetGiftCount(address _address, uint256 count);
    event Withdraw(address feeReceiverOne, uint256 feeAmountOne, address feeReceiverTwo, uint256 feeAmountTwo );

    function skribbleOf(uint256 skribbleId)
        external
        view
        returns (Capsule memory);

    function giftCountOf(address a) external view returns (uint256);

    function colorOf(uint256 skribbleId) external view returns (bytes3);

    function textOf(uint256 skribbleId)
        external
        view
        returns (bytes32[8] memory);

    function fontOf(uint256 skribbleId) external view returns (Font memory);

    function svgOf(uint256 skribbleId) external view returns (string memory);
    
    function rendererOf(uint256 SkribbleId) external view returns (address);

    function mint(
        bytes3 color,
        Font calldata font,
        bytes32[8] calldata text
    ) external payable returns (uint256);

    function mintGift(
        bytes3 color,
        Font calldata font,
        bytes32[8] calldata text
    ) external returns (uint256);

    function mintAsOwner(
        address to,
        bytes3 color,
        Font calldata font,
        bytes32[8] calldata text
    ) external returns (uint256);

    function setGiftCounts(
        address[] calldata addresses,
        uint256[] calldata counts
    ) external;

    function setTextAndFont(
        uint256 skribbleId,
        bytes32[8] calldata text,
        Font calldata font
    ) external;

    function setTextAndColor(
        uint256 SkribbleId,
        bytes32[8] calldata text,
        bytes3 color
    ) external;

    function setText(uint256 skribbleId, bytes32[8] calldata text) external;

    function setFont(uint256 skribbleId, Font calldata font) external;

    function setColor(uint256 skribbleId, bytes3 color) external;

    function setRendererOf(uint256 skribbleId, address renderer) external;

    function setDefaultRenderer(address renderer) external;

    function addValidRenderer(address renderer) external;

    function setCapsuleMetadata(address _CapsuleMetadata) external;

    function burn(uint256 skribbleId) external;

    function isValidFontForRenderer(Font memory font, address renderer)
        external
        view
        returns (bool);

    function isValidSkribbleText(uint256 skribbleId) external view returns (bool);

    function isValidRenderer(address renderer) external view returns (bool);

    function isValidColor(bytes3 color) external pure returns (bool);

    function contractURI() external view returns (string memory);

    function withdraw() external;

    function setFeeReceiverOne(address _feeReceiver) external;
    
    function setFeeReceiverTwo(address _feeReceiver) external;

    function setFeeTakeOne(uint _feeTakeOne) external;

    function setMintMaster(address _mintMaster) external;

    function setMintingPrice(uint256 _mint_price) external;

    function setRoyalty(uint256 _royalty) external;

    function setContractURI(string calldata _contractURI) external;

    function pause() external;

    function unpause() external;
}