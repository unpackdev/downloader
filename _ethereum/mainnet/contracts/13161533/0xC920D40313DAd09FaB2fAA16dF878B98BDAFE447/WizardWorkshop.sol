// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//      .->     _       (`-')   (`-')  _    (`-') _(`-')
//  (`(`-')/`) (_)      ( OO).->(OO ).-/ <-.(OO )( (OO ).->
// ,-`( OO).', ,-(`-'),(_/----. / ,---.  ,------,)\    .'_
// |  |\  |  | | ( OO)|__,    | | \ /`.\ |   /`. ''`'-..__)
// |  | '.|  | |  |  ) (_/   /  '-'|_.' ||  |_.' ||  |  ' |
// |  |.'.|  |(|  |_/  .'  .'_ (|  .-.  ||  .   .'|  |  / :
// |   ,'.   | |  |'->|       | |  | |  ||  |\  \ |  '-'  /
// `--'   '--' `--'   `-------' `--' `--'`--' '--'`------'
//
//      .->                 (`-') <-.(`-')  (`-').-> (`-').->            _  (`-')
//  (`(`-')/`)     .->   <-.(OO )  __( OO)  ( OO)_   (OO )__      .->    \-.(OO )
// ,-`( OO).',(`-')----. ,------,)'-'. ,--.(_)--\_) ,--. ,'-'(`-')----.  _.'    \
// |  |\  |  |( OO).-.  '|   /`. '|  .'   //    _ / |  | |  |( OO).-.  '(_...--''
// |  | '.|  |( _) | |  ||  |_.' ||      /)\_..`--. |  `-'  |( _) | |  ||  |_.' |
// |  |.'.|  | \|  |)|  ||  .   .'|  .   ' .-._)   \|  .-.  | \|  |)|  ||  .___.'
// |   ,'.   |  '  '-'  '|  |\  \ |  |\   \\       /|  | |  |  '  '-'  '|  |
// `--'   '--'   `-----' `--' '--'`--' '--' `-----' `--' `--'   `-----' `--'

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./IERC721.sol";

contract WizardWorkshop is ERC1155, Ownable, ERC1155Burnable {
    address public wizardsContractAddress;
    uint256 public _currentTokenID = 0;
    mapping(uint256 => address) public creators;
    mapping(uint256 => string) public tokenURIs;
    mapping(address => bool) public allowlist;

    event Minted(
        address creator,
        uint256 tokenId,
        uint256 supply,
        string tokenUri
    );

    modifier onlyWizards() {
        require(
            IERC721(wizardsContractAddress).balanceOf(msg.sender) > 0,
            'Only Wizards allowed in this workshop'
        );
        _;
    }

    modifier onlyOwnerOrAllowlisted() {
        require(
            owner() == _msgSender() || allowlist[_msgSender()],
            'Ownable: caller is not the owner or allowlisted'
        );
        _;
    }

    constructor(address _wizardsContractAddress) ERC1155('') {
        wizardsContractAddress = _wizardsContractAddress;
    }

    function uri(uint256 id) public view override returns (string memory) {
        require(bytes(tokenURIs[id]).length > 0, 'That token does not exist');
        return tokenURIs[id];
    }

    function _createToken(
        address initialOwner,
        address creator,
        uint256 totalTokenSupply,
        string calldata tokenUri,
        bytes calldata data
    ) internal returns (uint256) {
        require(bytes(tokenUri).length > 0, 'uri required');
        require(totalTokenSupply > 0, 'supply must be more than 0');
        require(
            totalTokenSupply <= 1000,
            'supply must be no greater than 1000'
        );

        uint256 _id = _currentTokenID + 1;
        _currentTokenID++;

        creators[_id] = creator;
        tokenURIs[_id] = tokenUri;
        emit URI(tokenUri, _id);
        emit Minted(creator, _id, totalTokenSupply, tokenUri);
        _mint(initialOwner, _id, totalTokenSupply, data);
        return _id;
    }

    function mint(
        address initialOwner,
        uint256 totalTokenSupply,
        string calldata tokenUri,
        bytes calldata data
    ) public onlyWizards returns (uint256) {
        return
            _createToken(
                initialOwner,
                msg.sender,
                totalTokenSupply,
                tokenUri,
                data
            );
    }

    function mintForCreator(
        address initialOwner,
        address creator,
        uint256 totalTokenSupply,
        string calldata tokenUri,
        bytes calldata data
    ) public onlyOwnerOrAllowlisted returns (uint256) {
        return
            _createToken(
                initialOwner,
                creator,
                totalTokenSupply,
                tokenUri,
                data
            );
    }

    function setAllowlist(address listingAddress, bool isListed)
        public
        onlyOwner
    {
        allowlist[listingAddress] = isListed;
    }
}
