// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ERC721Z {

    //project context
    string public name;
    string public symbol;
    string internal baseTokenURI;
    string internal baseTokenExtension;
    uint256 public totalSupply;

    constructor (
        string memory name_,
        string memory symbol_
    ) {
        name = name_;
        symbol = symbol_;
    }

    //Standard ERC721 Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    //Mappings
    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public isApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;


    //////Internal Write Functions
    ////Mint Functions
    //mint function
    function _mint(address to_, uint256 tokenId_) internal {
        require(to_ != address(0x0));
        require(ownerOf[tokenId_] == address(0x0));

        ownerOf[tokenId_] = to_;
        balanceOf[to_]++;
        totalSupply++;
        emit Transfer(address(0x0), to_, tokenId_);
    }

    //transfer function
    function _transfer(address from_, address to_, uint256 tokenId_) internal virtual {
        require(ownerOf[tokenId_] == from_);
        require(to_ != address(0x0));
        
        ownerOf[tokenId_] = to_;
        balanceOf[from_]--;
        balanceOf[to_]++;
    }

    ////Internal View functions
    //Is approved or the owner of the token
    function _isApprovedOrOwner(address spender_, uint256 tokenId_) internal view virtual returns (bool) {
        require(ownerOf[tokenId_] != address(0x0));
        address owner_ = ownerOf[tokenId_];
        return (spender_ == owner_ || spender_ == isApproved[tokenId_] || isApprovedForAll[owner_][spender_]);
    }
    //Checks to see if a token exists
    function _exists(uint256 tokenId_) internal view virtual returns (bool) {
        return ownerOf[tokenId_] != address(0x0);
    }

    //OZ standard function to convert Uint to String
    function _NumToString(uint256 value_) internal pure returns (string memory) {
        if (value_ == 0) { return "0"; }
        uint256 _iterate = value_;
        uint256 _digits;
        while (_iterate != 0) {
            _digits++;
            _iterate /= 10;
        }
        bytes memory _buffer = new bytes(_digits);
        while (value_ != 0) {
            _digits--;
            _buffer[_digits] = bytes1(uint8(48 + uint256(value_ % 10)));
            value_ /= 10;
        }
        return string(_buffer);
    }


    ////Approve functions
    //approve
    function _approve(address to_, uint256 tokenId_) internal virtual {
        if (isApproved[tokenId_] != to_) {
            isApproved[tokenId_] = to_;
            emit Approval(ownerOf[tokenId_], to_, tokenId_);
        }
    }
    //approve all
    function _setApprovalForAll(address owner_, address operator_, bool approved_) internal virtual {
        require(owner_ != operator_);
        isApprovedForAll[owner_][operator_] = approved_;
        emit ApprovalForAll(owner_, operator_, approved_);
    }

    ////Public Write Functions

    function approve(address to_, uint256 tokenId_) public virtual {
        address _owner = ownerOf[tokenId_];
        require(to_ != _owner);
        require(msg.sender == _owner || isApprovedForAll[_owner][msg.sender]);
        _approve(to_, tokenId_);
    }

    function setApprovalForAll(address operator_, bool approved_) public virtual {
        _setApprovalForAll(msg.sender, operator_, approved_);
    }

    // Public Transfer Functions

    function transferFrom(address from_, address to_, uint256 tokenId_) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId_));
        _transfer(from_, to_, tokenId_);
    }

    function safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes memory data_) public virtual {
        transferFrom(from_, to_, tokenId_);
        //erc721 receivable needed here
        if (to_.code.length != 0) {
            (, bytes memory _returned) = to_.staticcall(abi.encodeWithSelector(0x150b7a02, msg.sender, from_, tokenId_, data_));
            bytes4 _selector = abi.decode(_returned, (bytes4));
            require(_selector == 0x150b7a02);
        }
    }

    function safeTransferFrom(address from_, address to_, uint256 tokenId_) public virtual {
        safeTransferFrom(from_, to_, tokenId_, "");
    }


    //Custom Multi Transfer Functions
    function multiTransferFrom(address from_, address to_, uint256[] memory tokenIds_) public virtual {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            transferFrom(from_, to_, tokenIds_[i]);
        }
    }
    function multiSafeTransferFrom(address from_, address to_, uint256[] memory tokenIds_, bytes memory data_) public virtual {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            safeTransferFrom(from_, to_, tokenIds_[i], data_);
        }
    }

    function multiTransferToMany(address from_, address[] memory to_, uint256[] memory tokenIds_) public virtual {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            transferFrom(from_, to_[i], tokenIds_[i]);
        }
    }

    function multiSafeTransferToMany(
        address from_,
        address[] memory to_,
        uint256[] memory tokenIds_,
        bytes memory data_) public virtual {
            for (uint256 i = 0; i < tokenIds_.length; i++) {
                safeTransferFrom(from_, to_[i], tokenIds_[i], data_);
            }
    }

    //OZ support interface needed here
    function supportsInterface (bytes4 interfaceId_) public pure returns (bool) {
        return (interfaceId_ == 0x80ac58cd || interfaceId_ == 0x5b5e139f);
    }

    //Token URI stuff
    function tokenURI(uint256 tokenId_) public view virtual returns (string memory) {
        require(ownerOf[tokenId_] != address(0x0));
        return string(abi.encodePacked(baseTokenURI, _NumToString(tokenId_), baseTokenExtension));
    }

    function _setBaseTokenURI(string memory uri_) internal virtual {
        baseTokenURI = uri_;
    }
    function _setBaseTokenURI_Extension(string memory extension_) internal virtual {
        baseTokenExtension = extension_;
    }

    //Returns all the tokens owned by the given address
    function walletOfOwner(address address_) public virtual view returns (uint256[] memory) {
        uint256 _balance = balanceOf[address_];
        uint256[] memory _tokenIds = new uint256[] (_balance);
        uint256 _index;
        uint256 _supply = totalSupply;
        for (uint256 i = 0; i < _supply; i++) {
            if (ownerOf[i] == address(0x0) && _tokenIds[_balance - 1] == 0) {
                _supply++;
            }
            if (ownerOf[i] == address_) {
                _tokenIds[_index] = i;
                _index++;
            }
        }
        return _tokenIds;
    }
    function tokenOfOwnerByIndex(address address_, uint256 index_) public virtual view returns (uint256) {
        uint256[] memory _wallet = walletOfOwner(address_);
        return _wallet[index_];
    }   
}