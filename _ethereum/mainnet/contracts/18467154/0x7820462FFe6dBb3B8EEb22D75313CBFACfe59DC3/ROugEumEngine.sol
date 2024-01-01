// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: Tjo
/// @author: @yungwknd

import "./AdminControl.sol";
import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";
import "./IERC721Receiver.sol";
import "./ReentrancyGuard.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                   @@@@@@       @@@@@@,                                              //
//                                                                  .@@@@@@@*.*,,@@@@@@@*                                              //
//                                                                   @@@@@@@@@@@@@@@@@@@                                               //
//                                                         .@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                     //
//                                                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                    //
//                                                          @@@@@@@@@@@@@@@%     ,@@@@@@@@@@@@@@@                                      //
//                                                           @@@@@@@@@@@              @@@@@@@@@@&                                      //
//                                                          %@@@@@@@@@                 (@@@@@@@@@&%/.                                  //
//                                                     @@@@@@@@@@@@@@/                  @@@@@@@@@@@@@@#                                //
//                                                     @@@@@@@@@@@@@@*                  @@@@@@@@@@@@@@&                                //
//                                                      %@@@@@@@@@@@@@                 ,@@@@@@@@@%,                                    //
//                                                           @@@@@@@@@@#              @@@@@@@@@@@                                      //
//                                                           @@@@@@@@@@@@@&       .@@@@@@@@@@@@@@*                                     //
//                                    .@@@@@       @@@@@%  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%                                   //
//                                   .@@@@@@@     @@@@@@@/ #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.                                    //
//                                    @@@@@@@@@@@@@@@@@@@    /&.     @@@@@@@@@@@@@@@@@@@&                                              //
//                           @@@@( .@@@@@@@@@@@@@@@@@@@@@@@@.@@@@@%  %@@@@@@@@@@@@@@@@@@@                                              //
//                         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@      (@@@@@@                                              //
//                          #@@@@@@@@@@@@@@@@@&#%&@@@@@@@@@@@@@@@@*                    *@@@@@.                                         //
//                            @@@@@@@@@@@/            &@@@@@@@@@@,                     @@@@@@@                                         //
//                           (@@@@@@@@@/                @@@@@@@@@@.        @@@@@@&   (@@@@@@@@&*   @@@@@@%                             //
//                      @@@@@@@@@@@@@@#                  @@@@@@@@@@@@@@(   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                             //
//                      @@@@@@@@@@@@@@.                  @@@@@@@@@@@@@@&    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@                              //
//                      (@@@@@@@@@@@@@@                  @@@@@@@@@@@&/     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                             //
//                            @@@@@@@@@@               *@@@@@@@@@@  @@@@@@@@@@@@@@@@@%         @@@@@@@@@@@@@@@@@&                      //
//                            ,@@@@@@@@@@@&         .@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@               @@@@@@@@@@@@@@@#                     //
//                          &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.%@@@@@@@@@@@/                 @@@@@@@@@@@@*                       //
//                          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&   /@@@@@@@@@                   @@@@@@@@@.                         //
//                            @@&    @@@@@@@@@@@@@@@@@@@@@#     (#     *@@@@@@@@@                  .@@@@@@@@@                          //
//                                    #@@@@@@@@@@@@@@@@@@@         /@@@@@@@@@@@@@@                 @@@@@@@@@@@@@@.                     //
//                                    @@@@@@@.     @@@@@@@         .@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@                      //
//                                        %#         /              *@@@@&@@@@@@@@@@@@@@#,.,%@@@@@@@@@@@@@@@@@@@                       //
//                                                                         ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                              //
//                                                                         /@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.                             //
//                                                                        #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,                            //
//                                                                          ,@@@%     ,@@@@@@@      &@@@                               //
//                                                                                     @@@@@@@                                         //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                      More info on rouge.art                                                         //
//                                    Divine Colours by tjo (0x7c1D9b6aE3b1d4b355AFbBdfa5AB5Ec2B12f1c13)                               //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
contract ROugEumEngine is AdminControl, ReentrancyGuard, ICreatorExtensionTokenURI, IERC721Receiver {
    address public licenseContract;
    address public remixContract;
    address[] public artistsList;

    mapping(uint => string) public tokensURIs;
    mapping(uint => address) public artistForToken;
    mapping(address => uint[]) public tokensForArtist;
    mapping(uint => uint) public tokensForTokens;

    mapping(address => bool) public banned;

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return (
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            AdminControl.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId)
        );
    }

    string public license = '';

    function getLicense() public view returns(string memory) {
        return license;
    }

    function updateLicense(string memory _license) public adminRequired {
        license = _license;
    }

    modifier artistToken(uint _tokenId) {
      require(artistForToken[_tokenId] == msg.sender && !banned[msg.sender], "Invalid artist");
      _;
    }

    function getTokensForArtist(address artistAddress) public view returns(uint[] memory tokens) {
        return tokensForArtist[artistAddress];
    }

    function getArtists() public view returns(address[] memory) {
        return artistsList;
    }

    function adminBan(address creator, bool _banned) public adminRequired() {
        banned[creator] = _banned;
    }

    function adminUpdateTokenURI(string memory _tokenURI, uint _tokenId) public adminRequired() {
        tokensURIs[_tokenId] = _tokenURI;
    }

    function updateTokenURI(string memory _tokenURI, uint _tokenId) public artistToken(_tokenId) {
        tokensURIs[_tokenId] = _tokenURI;
    }

    function onERC721Received(address, address from, uint256 tokenId, bytes calldata data) external override nonReentrant returns (bytes4) {
        require(msg.sender == licenseContract, "Invalid NFT");
        require(data.length > 0, "Invalid data length");
        require(!banned[from], "Banned artist");
        
        // Burn it
        try IERC721CreatorCore(licenseContract).burn(tokenId) {
        } catch (bytes memory) {
            revert("Burn failure");
        }

        // Save the tokenURI data
        uint newTokenId = IERC721CreatorCore(remixContract).mintExtension(from);
        tokensURIs[newTokenId] = abi.decode(data, (string));
        artistForToken[newTokenId] = from;
        tokensForArtist[from].push(newTokenId);
        tokensForTokens[tokenId] = newTokenId;
        artistsList.push(from);

        return this.onERC721Received.selector;
    }

    function configure(address _licenseContract, address _remixContract) public adminRequired {
        require(licenseContract == address(0), "Already set");
        licenseContract = _licenseContract;
        remixContract = _remixContract;
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns(string memory) {
        require(creator == remixContract, "Invalid creator contract");
        return tokensURIs[tokenId];
    }
}