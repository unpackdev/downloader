// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title WrappedBustOfRomeOneYear
/// @author jpegmint.xyz

import "./INiftyBuilder.sol";
import "./ERC721Wrapper.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721.sol";

/**
 *  _      __                          __  ___           __         ___  ___                
 * | | /| / /______ ____  ___  ___ ___/ / / _ )__ _____ / /_  ___  / _/ / _ \___  __ _  ___ 
 * | |/ |/ / __/ _ `/ _ \/ _ \/ -_) _  / / _  / // (_-</ __/ / _ \/ _/ / , _/ _ \/  ' \/ -_)
 * |__/|__/_/  \_,_/ .__/ .__/\__/\_,_/ /____/\_,_/___/\__/  \___/_/  /_/|_|\___/_/_/_/\__/ 
 *                /_/  /_/                                                                  
 *
 * @dev Wrapping contract for ROME token to improve the TokenURI metadata.
 */
contract WrappedBustOfRomeOneYear is ERC721Wrapper, Ownable {
    using Strings for uint256;

    INiftyBuilder private immutable _niftyBuilderInstance;

    constructor(address niftyBuilderAddress) ERC721("Wrapped Bust of Rome (One Year)", "wROME") {
        _niftyBuilderInstance = INiftyBuilder(niftyBuilderAddress);
    }

    /**
     * @dev Add access control and force ROME contract address.
     */
    function updateApprovedTokenRanges(address contract_, uint256 minTokenId, uint256 maxTokenId) public override onlyOwner {
        require(contract_ == address(_niftyBuilderInstance), 'wROME: Can only approve ROME contract tokens.');
        _updateApprovedTokenRanges(contract_, minTokenId, maxTokenId);
    }

    /**
     * @dev TokenURI override to return metadata and IPFS/Arweave assets on-chain and dynamically.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {

        require(_exists(tokenId), "wROME: URI query for nonexistent token");

        string memory mintNumber = (tokenId - 100010000).toString();
        string memory ipfsHash = _niftyBuilderInstance.tokenIPFSHash(tokenId);
        string memory arweaveHash = _getTokenArweaveHash(ipfsHash);

        bytes memory byteString;
        byteString = abi.encodePacked(byteString, 'data:application/json;utf8,{');
        byteString = abi.encodePacked(byteString, '"name": "Eroding and Reforming Bust of Rome (One Year) #', mintNumber, '/671",');
        byteString = abi.encodePacked(byteString, '"created_by": "Daniel Arsham",');
        byteString = abi.encodePacked(byteString
            ,'"description": "**Daniel Arsham** (b. 1980)\\n\\n'
            ,'***Eroding and Reforming Bust of Rome (One Year)***, 2021\\n\\n'
            ,'With his debut NFT release, Daniel Arsham introduces a concept never before seen on Nifty Gateway. '
            ,'His piece will erode, reform, and change based on the time of year.",'
        );
        byteString = abi.encodePacked(byteString, '"external_url": "https://niftygateway.com/collections/danielarsham",');
        byteString = abi.encodePacked(byteString
            ,'"image": "https://arweave.net/', arweaveHash, '",'
            ,'"image_url": "https://arweave.net/', arweaveHash, '",'
            ,'"animation": "ipfs://', ipfsHash, '",'
            ,'"animation_url": "ipfs://', ipfsHash, '",'
        );
        byteString = abi.encodePacked(byteString, '"attributes":[{"trait_type": "Edition", "display_type": "number", "value": ', mintNumber, ', "max_value": 671}]');
        byteString = abi.encodePacked(byteString, '}');
        return string(byteString);
    }

    /**
     * @dev Returns Arweave hash for the preview image matching given IPFS hash.
     */
    function _getTokenArweaveHash(string memory ipfsHash) private pure returns (string memory) {
        bytes32 ipfsMatcher = keccak256(abi.encodePacked(ipfsHash));
             if (ipfsMatcher == keccak256("QmQdb77jfHZSwk8dGpN3mqx8q4N7EUNytiAgEkXrMPbMVw")) return "iOKh8ppTX5831s9ip169PfcqZ265rlz_kH-oyDXELtA"; //State 1
        else if (ipfsMatcher == keccak256("QmS3kaQnxb28vcXQg35PrGarJKkSysttZdNLdZp3JquttQ")) return "4iJ3Igr90bfEkBMeQv1t2S4ctK2X-I18hnbal2YFfWI"; //State 2
        else if (ipfsMatcher == keccak256("QmX8beRtZAsed6naFWqddKejV33NoXotqZoGTuDaV5SHqN")) return "y4yuf5VvfAYOl3Rm5DTsAaneJDXwFJGBThI6VG3b7co"; //State 3
        else if (ipfsMatcher == keccak256("QmQvsAMYzJm8kGQ7YNF5ziWUb6hr7vqdmkrn1qEPDykYi4")) return "29SOcovLFC5Q4B-YJzgisGgRXllDHoN_l5c8Tan3jHs"; //State 4
        else if (ipfsMatcher == keccak256("QmZwHt9ZhCgVMqpcFDhwKSA3higVYQXzyaPqh2BPjjXJXU")) return "d8mJGLKJhg1Gl2OW1qQjcH8Y8tYBCvNWUuGH6iXd18U"; //State 5
        else if (ipfsMatcher == keccak256("Qmd2MNfgzPYXGMS1ZgdsiWuAkriRRx15pfRXU7ZVK22jce")) return "siy0OInjmvElSk2ORJ4VNiQC1_dkdKzNRpmkOBBy2hA"; //State 6
        else if (ipfsMatcher == keccak256("QmWcYzNdUYbMzrM7bGgTZXVE4GBm7v4dQneKb9fxgjMdAX")) return "5euBxS7JvRrqb7fxh4wLjEW5abPswocAGTHjqlrkyBE"; //State 7
        else if (ipfsMatcher == keccak256("QmaXX7VuBY1dCeK78TTGEvYLTF76sf6fnzK7TJSni4PHxj")) return "7IK1u-DsuAj0nQzpwmQpo66dwpWx8PS9i-xv6aS6y6I"; //State 8
        else if (ipfsMatcher == keccak256("QmaqeJnzF2cAdfDrYRAw6VwzNn9dY9bKTyUuTHg1gUSQY7")) return "LWpLIs3-PUvV6WvXa-onc5QZ5FeYiEpiIwRfc_u64ss"; //State 9
        else if (ipfsMatcher == keccak256("QmSZquD6yGy5QvsJnygXUnWKrsKJvk942L8nzs6YZFKbxY")) return "vzLvsueGrzpVI_MZBogAw57Pi1OdynahcolZPpvhEQI"; //State 10
        else if (ipfsMatcher == keccak256("QmYtdrfPd3jAWWpjkd24NzLGqH5TDsHNvB8Qtqu6xnBcJF")) return "iEh79QQjaMjKd0I6d6eM8UYcFw-pj5_gBdGhTOTB54g"; //State 11
        else if (ipfsMatcher == keccak256("QmesagGNeyjDvJ2N5oc8ykBiwsiE7gdk9vnfjjAe3ipjx4")) return "b132CTM45LOEMwzOqxnPqtDqlPPwcaQ0ztQ5OWhBnvQ"; //State 12
        revert('wROME: Invalid IPFS hash');
    }

    /**
     * Recovery function to extract orphaned ROME tokens. Works only if wROME contract
     * owns unwrapped ROME token.
     */
    function recoverOrphanedToken(uint256 tokenId) external onlyOwner {
        require(!_exists(tokenId), "wROME: can't recover wrapped token");
        require(_niftyBuilderInstance.ownerOf(tokenId) == address(this), "wROME: can't recover token that is not own");
        _niftyBuilderInstance.safeTransferFrom(address(this), msg.sender, tokenId);
    }
}
