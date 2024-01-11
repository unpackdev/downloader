//  SPDX-License-Identifier: MIT

//  /$$   /$$ /$$$$$$$$ /$$$$$$$$                                  /$$             
// | $$$ | $$| $$_____/|__  $$__/                                 | $$             
// | $$$$| $$| $$         | $$ /$$  /$$  /$$  /$$$$$$   /$$$$$$  /$$$$$$   /$$$$$$$
// | $$ $$ $$| $$$$$      | $$| $$ | $$ | $$ /$$__  $$ /$$__  $$|_  $$_/  /$$_____/
// | $$  $$$$| $$__/      | $$| $$ | $$ | $$| $$$$$$$$| $$$$$$$$  | $$   |  $$$$$$ 
// | $$\  $$$| $$         | $$| $$ | $$ | $$| $$_____/| $$_____/  | $$ /$$\____  $$
// | $$ \  $$| $$         | $$|  $$$$$/$$$$/|  $$$$$$$|  $$$$$$$  |  $$$$//$$$$$$$/
// |__/  \__/|__/         |__/ \_____/\___/  \_______/ \_______/   \___/ |_______/ 

pragma solidity ^0.8.4;

import "./NFTweetMetadata.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721.sol";

contract NFTweets is ERC721, Ownable {
    uint256 public tokenCounter;
    using Strings for uint256;
    bool public saleIsActive = true;
    uint256 public MAX_SUPPLY = 1000;
    uint256 public MAX_PUBLIC_SUPPLY = 950;

    mapping (string => bool) public tweetChecker;
    mapping (uint256 => string) public tokenIdToTweet;

    constructor() ERC721("NFTweets", "NFTs") { tokenCounter = 0; }

    function mint(string memory tweet) public payable {
        tokenCounter = tokenCounter+1;
        require(tokenCounter <= MAX_PUBLIC_SUPPLY, "Minted out");
        require(saleIsActive, "Sale NOT active yet");
        require(msg.value == getPrice(), "Payment too low");
        require(tweetChecker[tweet] == false, "Tweet used before, try something else!");
        _safeMint(msg.sender, tokenCounter);
        tweetChecker[tweet] = true;
        tokenIdToTweet[tokenCounter] = tweet;
    }

    function mintOwner(string memory tweet, address to) public onlyOwner {
        tokenCounter = tokenCounter+1;
        require(tokenCounter <= MAX_SUPPLY, "Minted out");
        require(!saleIsActive, "Sale is STILL active");
        require(tweetChecker[tweet] == false, "Tweet used before, try something else!");
        _safeMint(to, tokenCounter);
        tweetChecker[tweet] = true;
        tokenIdToTweet[tokenCounter] = tweet;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory tokenName = string(abi.encodePacked("NFTweet #", tokenId.toString()));
        string memory description = tokenIdToTweet[tokenId];
        string memory initialSvg = '<svg width="500" height="225" xmlns="http://www.w3.org/2000/svg"><rect rx="15" width="500" height="225" fill="#FFF" stroke="#000" stroke-width="2"/><circle cx="80" cy="95" r="40" fill="#5394d3"/><ellipse cx="80" cy="95" rx="15" ry="20" fill="#F8F0E3"/><text x="130" y="70" font-family="Arial" font-size="1.3em" font-weight="bold">NFTweets</text><text x="232.5" y="70" font-family="Arial" font-size="1.3em" font-color="gray">@NFTweetsDAO - Apr 9</text><foreignObject x="130" y="80" width="275" height="130"><div style="font-size:1.2em;font-family:Arial;overflow:auto" xmlns="http://www.w3.org/1999/xhtml">';
        string memory endSvg = '</div></foreignObject></svg>';
        return NFTweetMetaData.tokenURI(tokenName, description, initialSvg, endSvg);
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function getPrice() public view returns (uint256) {
        return (tokenCounter / 100 + 1) * 0.05 ether;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
