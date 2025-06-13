import 'package:flutter/material.dart';
import 'package:picto_grid/l10n/app_localizations.dart';
import 'package:picto_grid/models/pictogram.dart';
import 'package:picto_grid/services/local_pictogram_service.dart';

class PictogramSearchDropdown extends StatefulWidget {

  const PictogramSearchDropdown({
    super.key,
    required this.onPictogramSelected,
  });
  final Function(Pictogram) onPictogramSelected;

  @override
  State<PictogramSearchDropdown> createState() =>
      _PictogramSearchDropdownState();
}

class _PictogramSearchDropdownState extends State<PictogramSearchDropdown> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LocalPictogramService _pictogramService =
      LocalPictogramService.instance;
  List<Pictogram> _searchResults = [];
  bool _isLoading = false;
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() {
          _showDropdown = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _searchPictograms(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showDropdown = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showDropdown = true;
    });

    try {
      final results = await _pictogramService.searchPictograms(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.searchPictoGramPlaceHolder,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults = [];
                        _showDropdown = false;
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (value) {
            _searchPictograms(value);
          },
        ),
        if (_showDropdown)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _searchResults.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          AppLocalizations.of(context)!.searchFieldNoResults,
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final pictogram = _searchResults[index];
                          return ListTile(
                            leading: SizedBox(
                              width: 40,
                              height: 40,
                              child: pictogram.imageUrl.startsWith('assets/')
                                  ? Image.asset(
                                      pictogram.imageUrl,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(Icons.error_outline,
                                            color: Colors.red);
                                      },
                                    )
                                  : Image.network(
                                      pictogram.imageUrl,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(Icons.error_outline,
                                            color: Colors.red);
                                      },
                                    ),
                            ),
                            title: Text(pictogram.keyword),
                            onTap: () {
                              widget.onPictogramSelected(pictogram);
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                                _showDropdown = false;
                              });
                              _focusNode.unfocus();
                            },
                          );
                        },
                      ),
          ),
      ],
    );
  }
}
