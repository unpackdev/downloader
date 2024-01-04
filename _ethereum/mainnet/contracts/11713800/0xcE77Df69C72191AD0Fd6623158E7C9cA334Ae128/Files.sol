pragma experimental ABIEncoderV2;
pragma solidity 0.6.0;

import "./OwnableUpgradeable.sol";
import "./StringsUpgradeable.sol";

contract Files is OwnableUpgradeable {


	// First Version of File Metadata:
	// Title: Breaking the Chain
	// Type: Audio/mp3 - Image/jpg
	// Album: Living an Impossible Dream. OR [Series]: Runa Motorbike at Night
	// Copyright: 2020 QMP (GnuPG ID FFE28038)
	// Website: https://QuantumIndigo.org
	// IPFS URL: (IPFS URL)
	// Comment: The world's first decentralised media arts collective.
	// Blockchain Date: [Date]
	// SHA256: [sha256_hash]

    struct FileOutput {
		string separator;
		string title;
		string media_type;
		string album_series;
		string copyright;
		string website;
		string ipfs_hash;
		string comment;
		string blockchain_date;
		string sha_hash;
    }

    uint256 private size;

	// Searches will be done nased on IPFS hash and SHA256 Hash.

    mapping(uint256 => string) filesIpfsHashIndex;
    mapping(string => uint256[]) filesByIpfsHash;

	mapping(uint256 => string) filesShaHashIndex;
    mapping(string => uint256[]) filesByShaHash;

  
	mapping(uint256 => string) filesTitleIndex;
	mapping(uint256 => string) filesMediaTypeIndex;
    mapping(uint256 => string) filesAlbumSeriesIndex;
	mapping(uint256 => string) filesCopyrightIndex;
	mapping(uint256 => string) filesWebsiteIndex;
	mapping(uint256 => string) filesCommentIndex;
	mapping(uint256 => uint256) filesBlockchainDateIndex;
    
    function initialize() initializer public {
        __Ownable_init();
    }

    function addFile(string[] memory metadata) public onlyOwner returns (uint256) {

        require( metadata.length == 8);

		// Data is pasted in FileOutput Order. Blockchain date is skipped because it will be added when the block is mined.
		// 8 Items in total

        string memory _title = metadata[0];
	    string memory _media_type = metadata[1];
        string memory _album_series = metadata[2];
		string memory _copyright = metadata[3];
        string memory _website = metadata[4];
	    string memory _ipfs_hash = metadata[5];
        string memory _comment = metadata[6];
		string memory _sha_hash = metadata[7];
 

        filesTitleIndex[size] = _title;
        filesMediaTypeIndex[size] = _media_type;
        filesAlbumSeriesIndex[size] = _album_series;
        filesCopyrightIndex[size] = _copyright;
        filesWebsiteIndex[size] = _website;
        filesIpfsHashIndex[size] = _ipfs_hash;
        filesCommentIndex[size] = _comment;
        filesBlockchainDateIndex[size] = block.timestamp;
		filesShaHashIndex[size] = _sha_hash;


        filesByIpfsHash[_ipfs_hash].push(size);
        filesByShaHash[_sha_hash].push(size);

        size = size + 1;
        return size;
    }

    function findFilesByIpfsHash(string calldata ipfs_hash) view external returns (FileOutput[] memory) {
        return findFilesByKey(1, ipfs_hash);
    }

    function findFilesByShaHash(string calldata sha_hash) view external returns (FileOutput[] memory) {
        return findFilesByKey(2, sha_hash);
    }

    function findFilesByKey(int key, string memory hash) view internal returns (FileOutput[] memory) {
        uint256 len;

        if(key == 1){
            len = filesByIpfsHash[hash].length;
        } else {
            len = filesByShaHash[hash].length;
        }

        string[] memory _title = new string[](len);
        string[] memory _media_type = new string[](len);
        string[] memory _album_series = new string[](len);
        string[] memory _copyright = new string[](len);
        string[] memory _website = new string[](len);
        string[] memory _ipfs_hash = new string[](len);
        string[] memory _comment = new string[](len);
        string[] memory _blockchain_date = new string[](len);		
		string[] memory _sha_hash = new string[](len);	

        for (uint256 index = 0; index < len; index++){
            uint256 id;
            if(key == 1){
                id = filesByIpfsHash[hash][index];
            } else {
                id = filesByShaHash[hash][index];
            }

			(uint year, uint month, uint day) = timestampToDate(filesBlockchainDateIndex[id]);

            _title[index] = filesTitleIndex[id];
            _media_type[index] = filesMediaTypeIndex[id];
            _album_series[index] = filesAlbumSeriesIndex[id];
            _copyright[index] = filesCopyrightIndex[id];
            _website[index] = filesWebsiteIndex[id];
            _ipfs_hash[index] = filesIpfsHashIndex[id];
            _comment[index] = filesCommentIndex[id];
			_blockchain_date[index] = concat( StringsUpgradeable.toString(day),  "-",  StringsUpgradeable.toString(month), "-", StringsUpgradeable.toString(year) );
			_sha_hash[index] = filesShaHashIndex[id];	

        }

        
		FileOutput[] memory outputs = new FileOutput[](_ipfs_hash.length);
		for (uint256 index = 0; index < _ipfs_hash.length; index++) {

            FileOutput memory output;
            if (keccak256(abi.encodePacked(_media_type[index])) == keccak256(abi.encodePacked("Audio/mp3"))) {
                output = FileOutput(
                            "****",
                            concat("Title: ", _title[index]),
                            concat("Type: ", _media_type[index]),
                            concat("Album: ", _album_series[index]),
                            concat("Copyright: ", _copyright[index]),
                            concat("Website: ", _website[index]),
                            concat("IPFS URL: https://ipfs.io/ipfs/", _ipfs_hash[index]),
                            concat("Comment: ", _comment[index]),
                            concat("Blockchain Date: ", _blockchain_date[index]),
                            concat("SHA256: ", _sha_hash[index])
                        );
            } else {
                output = FileOutput(
                            "****",
                            concat("Title: ", _title[index]),
                            concat("Type: ", _media_type[index]),
                            concat("Series: ", _album_series[index]),
                            concat("Copyright: ", _copyright[index]),
                            concat("Website: ", _website[index]),
                            concat("IPFS URL: https://ipfs.io/ipfs/", _ipfs_hash[index]),
                            concat("Comment: ", _comment[index]),
                            concat("Blockchain Date: ", _blockchain_date[index]),
                            concat("SHA256: ", _sha_hash[index])
                        );
            }

			outputs[index] = output;
		}
		return outputs;

	}

	function concat(string memory a, string memory b) private pure returns (string memory) {
		return string(abi.encodePacked(a, b));
	}

	function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / (24 * 60 * 60));
    }

    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + 2440588;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

	function concat(string memory a, string memory b, string memory c, string memory d, string memory e) private pure returns (string memory) {
		return string(abi.encodePacked(a, b, c, d, e));
	}

}