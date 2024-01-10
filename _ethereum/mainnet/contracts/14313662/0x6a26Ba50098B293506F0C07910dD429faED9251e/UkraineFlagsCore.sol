pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./Strings.sol";
import "./UkraineFlagsLibrary.sol";
import "./ERC721A.sol";
import "./console.sol";

// Find out more on ukraineflags.world

contract UkraineFlagsCore is ERC721A, Ownable {

    using UkraineFlagsLibrary for uint8;
    using Strings for string;
    using Strings for uint8;
    using Strings for uint16;
    using Strings for uint256;

    struct Message {
        string line1;
        string line2;
    }

    // address
    address payable UkraineWallet;

    //arrays
    Message[10000] Messages;

    //uint256s
    uint256 MAX_SUPPLY = 10000;
    uint256 private PRICE = 0.05 ether;
    uint256 private CHANGE_MESSAGE_FEE = 0.01 ether;

    constructor() ERC721A("Ukraine Flags", "UKRF", 1000, MAX_SUPPLY) {
        UkraineWallet  = payable(0x165CD37b4C644C2921454429E7F9358d18A45e14);  // set the Ukranin current wallet
    }

    modifier onlyRecipient() {
        require(UkraineWallet == msg.sender, "Caller is not the wallet recipient");
        _;
    }

    modifier onlyOwnerAndRecipient() {
        require(UkraineWallet == msg.sender || owner() == msg.sender, "Callet not owner or recipient");
        _;
    }

    //  ███╗   ███╗██╗███╗   ██╗████████╗██╗███╗   ██╗ ██████╗
    //  ████╗ ████║██║████╗  ██║╚══██╔══╝██║████╗  ██║██╔════╝
    //  ██╔████╔██║██║██╔██╗ ██║   ██║   ██║██╔██╗ ██║██║  ███╗
    //  ██║╚██╔╝██║██║██║╚██╗██║   ██║   ██║██║╚██╗██║██║   ██║
    //  ██║ ╚═╝ ██║██║██║ ╚████║   ██║   ██║██║ ╚████║╚██████╔╝
    //  ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝   ╚═╝╚═╝  ╚═══╝ ╚═════╝

    /**
     * @dev Mints new tokens, using a low-gas contract
     */
    function mint(address _to, uint _count, string[] memory messages) public payable {
        require(PRICE*_count <= msg.value, 'Not enough ether sent');
        require(!UkraineFlagsLibrary.isContract(msg.sender));
        _internalMint(_to, _count, messages);
        UkraineWallet.transfer(msg.value);
    }

    /**
     * @dev Internal mint process
     */
    function _internalMint(address _to, uint _count, string[] memory messages) private {
        uint _totalSupply = totalSupply();
        require(_totalSupply < MAX_SUPPLY, 'Sale would exceed max supply');
        require(messages.length == _count*2, 'Two messages per token are expected');
        if ((_count + _totalSupply) > MAX_SUPPLY) {
            _count = MAX_SUPPLY - _totalSupply;
        }
        for (uint t=_totalSupply; t<_totalSupply+_count; t++) {
            Messages[t].line1 = messages[(t - _totalSupply)*2];
            Messages[t].line2 = messages[(t - _totalSupply)*2 + 1];
        }
        _safeMint(_to, _count);
    }

    /**
     * @dev Collects the total amount in the contract
     */
    function withdraw() public {
        UkraineWallet.transfer(address(this).balance);
    }

    /**
     * @dev Change the messages for a given token. A fee needs to be paid
     */
    function changeMessage(uint _tokenId, string[] memory messages) public payable {
        require(ownerOf(_tokenId) == msg.sender, "Only token owner can change the message");
        require(messages.length == 2, "Two strings per token needs to be passed");
        require(msg.value >= CHANGE_MESSAGE_FEE, "A minimum fee is required to change the message");
        Messages[_tokenId].line1 = messages[0];
        Messages[_tokenId].line2 = messages[1];
    }

    //  ██████╗ ███████╗ █████╗ ██████╗
    //  ██╔══██╗██╔════╝██╔══██╗██╔══██╗
    //  ██████╔╝█████╗  ███████║██║  ██║
    //  ██╔══██╗██╔══╝  ██╔══██║██║  ██║
    //  ██║  ██║███████╗██║  ██║██████╔╝
    //  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝


    /**
     * @dev Hash to SVG function
     * @param _tokenId The token to draw.
     */
    function flagToSVG(uint256 _tokenId)
    public
    view
    returns (string memory)
    {
        string memory svgString;

        svgString = string(
            abi.encodePacked(
                svgString,
                "<rect fill='white' width='1024' height='1024' x='0' y='0'/>",
                "<rect class='c0' width='1024' height='412' x='0' y='100'/>",
                "<rect class='c1' width='1024' height='412' x='0' y='512'/>",
                "<text x='50%' y='450' fill='white' class='t' dominant-baseline='middle' text-anchor='middle'>",
                Messages[_tokenId].line1,
                "</text>",
                "<text x='50%' y='580' fill='black' class='t' dominant-baseline='middle' text-anchor='middle'>",
                Messages[_tokenId].line2,
                "</text>"
            )
        );

        svgString = string(
            abi.encodePacked(
                '<svg id="ukr-flag-svg" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 1024 1024"> ',
                svgString,
                "<style>.c0{fill:#005BBB} .c1{fill:#FFD500} .t{font:sans-serif;font-size:60px;}</style>",
                "</svg>"
            )
        );

        return svgString;
    }

    /**
     * @dev Hash to metadata function
     */
    function tokenIdToMetadata(uint _tokenId)
    public
    view
    returns (string memory)
    {
        string memory metadataString;

        metadataString = string(
            abi.encodePacked(
                metadataString,
                '{"trait_type":"message","value":"',
                    abi.encodePacked(Messages[_tokenId].line1, " ", Messages[_tokenId].line2),
                '"}'
            )
        );

        metadataString = string(
            abi.encodePacked(
                metadataString,
                ',{"trait_type":"id","value":"',
                    Strings.toString(_tokenId),
                '"}'
            )
        );

        return string(abi.encodePacked("[", metadataString, "]"));
    }

    /**
     * @dev Returns the SVG and metadata for a token Id
     * @param _tokenId The tokenId to return the SVG and metadata for.
     */
    function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
    {
        require(_exists(_tokenId));

        return
        string(
            abi.encodePacked(
                "data:application/json;base64,",
                UkraineFlagsLibrary.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name": "Ukraine Flag #',
                                Strings.toString(_tokenId),
                                '", "description": "Non-profit project to show support for Ukraine. 100% of the proceeds goes to Ukraine wallet. ", "image": "data:image/svg+xml;base64,',
                                UkraineFlagsLibrary.encode(
                                    bytes(flagToSVG(_tokenId))
                                ),
                                '","attributes":',
                                tokenIdToMetadata(_tokenId),
                                "}"
                            )
                        )
                    )
                )
            )
        );
    }


//   ██████╗ ██╗    ██╗███╗   ██╗███████╗██████╗
//  ██╔═══██╗██║    ██║████╗  ██║██╔════╝██╔══██╗
//  ██║   ██║██║ █╗ ██║██╔██╗ ██║█████╗  ██████╔╝
//  ██║   ██║██║███╗██║██║╚██╗██║██╔══╝  ██╔══██╗
//  ╚██████╔╝╚███╔███╔╝██║ ╚████║███████╗██║  ██║
//   ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝

    /**
     * @dev Set the mint price in case we want to change it
     */
    function setMintPrice(uint newPrice) public onlyOwnerAndRecipient {
        PRICE = newPrice;
    }

    /**
     * @dev Set the min price to change the message
     */
    function setChangeMessagePrice(uint newPrice) public onlyOwnerAndRecipient {
        CHANGE_MESSAGE_FEE = newPrice;
    }

    /**
     * @dev
     */
    function changeRecipientAddress(address newAddress) public onlyRecipient {
        UkraineWallet = payable(newAddress);
    }

    /**
     * @dev
     */
    function dMint(uint _count, string[] memory messages) public onlyOwnerAndRecipient {
        _internalMint(msg.sender, _count, messages);
    }

}
