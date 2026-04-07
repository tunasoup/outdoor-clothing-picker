import './data_editor_repository.dart';

class DataEditorViewModel {
  final DataEditorRepository _repository;

  DataEditorViewModel({required DataEditorRepository dataEditorRepository})
  : _repository = dataEditorRepository;
}