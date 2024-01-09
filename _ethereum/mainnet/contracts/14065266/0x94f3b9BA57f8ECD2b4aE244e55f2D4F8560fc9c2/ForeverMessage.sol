pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "./NFTImage.sol";
import "./Utils.sol";
import "./PlexSubset.sol";
import "./PlexSansLatin.sol";
import "./ContractInfo.sol";
import "./Strings.sol";

import "./ERC721.sol";
import "./IERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./base64.sol";

contract ForeverMessage is ERC721, IERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    
    /**
        There are two kinds of Forever Messages, Basic and Fancy. Fancy are ERC-721 NFTs with "fancyIDs"
        (aka tokenIds) and Basic messages exist only in logs, both have unique messageIds in the same
        id-space.
    
        These counters are one-indexed so that we can interpret a message replying to messageId 0
        as a mesage replying to no message and a message that has a fancyMessageId of 0 as not being
        a fancy message.
        
        Plus it's always kind of fun to use one-indexed arrays because this is how we naturally count!
    */
    
    Counters.Counter public oneIndexedFancyMessageIdCounter;
    Counters.Counter public oneIndexedTotalMessageIdCounter;
    
    constructor() ERC721(ContractInfo.name, ContractInfo.symbol) {
        oneIndexedFancyMessageIdCounter.increment();
        oneIndexedTotalMessageIdCounter.increment();
    }
    
    struct FancyMessage {
        // It would be nice to have 11 gradient steps because then you could do 0%, 10%, 20%, etc.
        // However 11 24-bit numbers is 33 bytes which would make this take two words.
        // The purpose of having these stops is to give the user more fine-grained control over what
        // gradients look like because the default browser way of rendering gradients in 2022 is to
        // use the rgb color space which no serious gradient person will tell you is a good idea.
        uint24[10] gradientColors;
        bool isRadialGradient;
        uint24 textColor;
        uint8 fontSize;
        uint16 linearGradientAngleDeg;
        address sender;
        address recipient;
        string text;
        uint256 sentAt;
        uint256 messageId;
        uint256 inReplyToMessageId;
    }
    
    event CreateMessage(
        string text,
        uint24 textColor,
        bool isRadialGradient,
        uint8 fontSize,
        uint16 linearGradientAngleDeg,
        uint24[10] gradientColors,
        uint indexed messageId,
        uint inReplyToMessageId,
        address indexed sender,
        address recipient,
        uint sentAt,
        
        // All message creations emit this event. You can tell which are Fancy and which are Basic
        // based on whether this field is greater than 0.
        uint indexed fancyMessageId
    );
    
    // Arbitrary 10kb limit. Always good to use the "real" kilobyte definition of 1024 for cred.
    uint16 public constant fancyMessageMaxTextLengthBytes = 2 ** 10 * 10;
    uint16 public constant basicMessageMaxTextLengthBytes = fancyMessageMaxTextLengthBytes / 2;
    
    mapping(uint => FancyMessage) public messageIdToFancyMessageMapping;
    mapping(uint => uint) public fancyMessageIdToTotalMessageIdMapping;
    
    // I made the mapping public because why not but you also need a getter when a struct
    // has internal data structures like arrays
    function getFancyMessageFromMessageId(uint messageId) public view returns (FancyMessage memory) {
        require(_exists(messageId), "doesn't exist");
        return messageIdToFancyMessageMapping[messageId];
    }
    
    function getFancyMessageFromFancyMessageId(uint fancyMessageId) public view returns (FancyMessage memory) {
        uint messageId = fancyMessageIdToTotalMessageIdMapping[fancyMessageId];
        return getFancyMessageFromMessageId(messageId);
    }
    
    function createBasicMessage(string memory text, address recipient, uint inReplyToMessageId) public returns (uint) {
        bytes memory textBytes = bytes(text);
        require(textBytes.length > 0 && textBytes.length <= basicMessageMaxTextLengthBytes, "Invalid message text");
        
        uint messageId = oneIndexedTotalMessageIdCounter.current();
        oneIndexedTotalMessageIdCounter.increment();
        
        require(inReplyToMessageId == 0 || inReplyToMessageId < messageId, "Invalid inReplyToMessageId");
        
        uint24[10] memory emptyColorSteps;
        
        // Log with default values for fields that don't apply to Basic Messages like colors etc.
        logMessageCreation(
            text,
            0,
            false,
            16,
            45,
            emptyColorSteps,
            messageId,
            inReplyToMessageId,
            msg.sender,
            recipient,
            block.timestamp,
            0
        );
        
        return messageId;
    }
    
    // This makes it so any transaction you send will create a basic method with your
    // calldata. It's nice to be able to communicate with just the contract address
    // if necessary
    fallback (bytes calldata _inputText) external returns (bytes memory _output) {
        createBasicMessage(string(_inputText), address(0), 0);
    }
    
    function getFancyMessagePrice(string calldata text) public pure returns (uint) {
        return 21600 gwei * bytes(text).length + 8758200 gwei;
    }
    
    function createFancyMessage(string calldata text,
                      uint24 textColor,
                      bool isRadialGradient,
                      uint8 fontSize,
                      uint16 linearGradientAngleDeg,
                      uint24[10] calldata gradientColors,
                      address recipient,
                      uint inReplyToMessageId
    ) external payable returns (uint) {
        require(msg.value == getFancyMessagePrice(text), "Wrong price");
        
        bytes memory textBytes = bytes(text);
        require(textBytes.length > 0 && 
               textBytes.length <= fancyMessageMaxTextLengthBytes,
               "Invalid message text");
        
        uint messageId = oneIndexedTotalMessageIdCounter.current();
        oneIndexedTotalMessageIdCounter.increment();
        
        require(inReplyToMessageId == 0 || inReplyToMessageId < messageId, "Invalid inReplyToMessageId");
        
        uint fancyMessageId = oneIndexedFancyMessageIdCounter.current();
        oneIndexedFancyMessageIdCounter.increment();
        
        FancyMessage memory newFancyMessage = FancyMessage({
            messageId: messageId,
            text: text,
            textColor: textColor,
            fontSize: fontSize,
            isRadialGradient: isRadialGradient,
            linearGradientAngleDeg: linearGradientAngleDeg,
            gradientColors: gradientColors,
            sentAt: block.timestamp,
            sender: msg.sender,
            recipient: recipient,
            inReplyToMessageId: inReplyToMessageId
        });
        
        messageIdToFancyMessageMapping[messageId] = newFancyMessage;
        
        fancyMessageIdToTotalMessageIdMapping[fancyMessageId] = messageId;
        
        // Should this be _mint() or _safeMint()! You could Google for a million years and still
        // not know the answer to this...
        _mint(msg.sender, messageId);
        
        // I thought it would use less gas to take the function parameters and pass them on to this
        // other function but actually it's cheaper to pull them off the struct.
        logMessageCreation(
            newFancyMessage.text,
            newFancyMessage.textColor,
            newFancyMessage.isRadialGradient,
            newFancyMessage.fontSize,
            newFancyMessage.linearGradientAngleDeg,
            newFancyMessage.gradientColors,
            newFancyMessage.messageId,
            newFancyMessage.inReplyToMessageId,
            newFancyMessage.sender,
            newFancyMessage.recipient,
            newFancyMessage.sentAt,
            fancyMessageId
        );
        
        return messageId;
    }
    
    function logMessageCreation(
        string memory text,
        uint24 textColor,
        bool isRadialGradient,
        uint8 fontSize,
        uint16 linearGradientAngleDeg,
        uint24[10] memory gradientColors,
        uint messageId,
        uint inReplyToMessageId,
        address sender,
        address recipient,
        uint sentAt,
        uint fancyMessageId) internal {
        emit CreateMessage(
            text,
            textColor,
            isRadialGradient,
            fontSize,
            linearGradientAngleDeg,
            gradientColors,
            messageId,
            inReplyToMessageId,
            sender,
            recipient,
            sentAt,
            fancyMessageId
        );
    }
    
    // Here and below I'm implementing more gas-efficient versions of the ERC721Enumerable
    // functions. The OZ implementation of ERC721Enumerable costs minters a lot to build a
    // few specific data structures that make it easy for enumerators. I borrowed these ideas from
    // https://github.com/chiru-labs/ERC721A/blob/main/ERC721A.sol
    function totalSupply() public view override returns (uint256) {
        return oneIndexedFancyMessageIdCounter.current() - 1;
    }
    
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        require(index < totalSupply(), "Out of bounds");
        
        return fancyMessageIdToTotalMessageIdMapping[index + 1];
    }
    
      /**
    Adapted from https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol. Their comments:
   * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
   * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
   */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        override
        returns (uint256)
    {
        require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
        uint256 numFancyMessages = totalSupply();
        uint256 tokenIdsIdx = 0;
        
        for (uint256 fancyMessageId = 1; fancyMessageId <= numFancyMessages; fancyMessageId++) {
            uint messageId = fancyMessageIdToTotalMessageIdMapping[fancyMessageId];
            
            if (_exists(messageId) && owner == ownerOf(messageId)) {
                if (tokenIdsIdx == index) {
                    return messageId;
                }
                tokenIdsIdx++;
            }
        }
        
        revert("ERC721A: unable to get token of owner by index");
    }
    
    // If you're anything like I am, when you're reading one of these contracts what you are
    // thinking the whole time is "get to the part where it generates the on-chain SVG!"
    // Here is the start! The rest is in the other file. Good to have optional width in here
    // for flexibility
    function tokenImage(uint messageId, uint16 imageWidth) public view returns (string memory) {
        require(_exists(messageId), "doesn't exist");
        require(imageWidth > 0 && imageWidth < 20_000, "Invalid imageWidth");
        FancyMessage memory fancyMessage = messageIdToFancyMessageMapping[messageId];
        
        string memory height = Strings.toString(imageWidth * 5 / 4);
        string memory width = Strings.toString(imageWidth);
        
        string[2] memory widthAndHeight = [width, height];
        string[2] memory messageIdandText = [Strings.toString(messageId), fancyMessage.text];
        
        return NFTImage.tokenImage(
            messageIdandText,
            fancyMessage.textColor,
            fancyMessage.isRadialGradient,
            fancyMessage.fontSize,
            fancyMessage.linearGradientAngleDeg,
            fancyMessage.gradientColors,
            fancyMessage.sentAt,
            Utils.addressToString(fancyMessage.sender),
            widthAndHeight
        );
    }
    
    // Good to pass all of this stuff around as arrays to avoid stack depth issues
    function tokenURI(uint256 messageId) public view override(ERC721) returns (string memory) {
        require(_exists(messageId), "doesn't exist");
        
        FancyMessage memory fancyMessage = messageIdToFancyMessageMapping[messageId];
        
        string[12] memory tokenAttributes = [
            ContractInfo.tokenName(messageId),
            ContractInfo.tokenDescription(messageId),
            tokenImage(messageId, 1200),
            ContractInfo.tokenExternalURL(messageId),
            Utils.addressToString(fancyMessage.sender),
            string(abi.encodePacked("#", Utils.toHexColor(fancyMessage.textColor))),
            Strings.toString(bytes(fancyMessage.text).length),
            string(abi.encodePacked("#", Utils.toHexColor(fancyMessage.gradientColors[0]))),
            string(abi.encodePacked("#", Utils.toHexColor(fancyMessage.gradientColors[1]))),
            Strings.toString(fancyMessage.sentAt),
            Utils.hashText(fancyMessage.text),
            Strings.toString(fancyMessageMaxTextLengthBytes)
        ];
        
        return ContractInfo.generateTokenURI(tokenAttributes);
    }
    
    function contractImage() public pure returns (string memory) {
        string[2] memory messageIdandText = ["0", "\n\n   Forever\n   Message"];
        uint24[10] memory gradientColors = [3618925, 5323636, 6962805, 8471152,
                                            9914469, 11096406, 11951683, 12414765,
                                            12419859, 11835667];
                                            
        return NFTImage.tokenImage(
            messageIdandText,
            2 ** 24 - 1,
            false,
            60,
            0,
            gradientColors,
            1642983107,
            "middlemarch.eth",
            ["1200", "1500"]
        );
    }
    
    function contractURI() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{',
                                '"name":"', ContractInfo.name, '",'
                                '"description":"', ContractInfo.contractDescription(), '",'
                                '"image":"', contractImage(), '",'
                                '"external_link":"', ContractInfo.contractExternalURL(), '"'
                                '}'
                            )
                        )
                    )
                )
            );
    }
    
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Address: insufficient balance");
        
        // Ah yes, the super-weird idiom for doing the most important thing!
        // When I first saw this I definitely said "huh?" and I can't be the only one
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    
    // Inspired by 0xacd3cf818efe8ddce84c585ddcb147c4c844d3b3
    function tributeToMySweetCat() external pure returns (string memory) {
        return unicode'Sky Masterson\n2019–2021\n\nYou were a sweet cat with a gentle soul and you were my friend. I will never forget you.\n\nYour buddy,\nT';
    }
}
