import {
  Component,
  Input,
  Output,
  EventEmitter,
  OnChanges,
  OnInit,
  SimpleChanges
} from '@angular/core';

import { SolrIndex, SuggestedSolrField } from '../../../../models';
import {
  SolrService
} from '../../../../services';

@Component({
  selector: 'app-smui-admin-suggested-fields-list',
  templateUrl: './suggested-fields-list.component.html'
})
export class SuggestedFieldsListComponent implements OnInit, OnChanges {

  @Input() solrIndex: SolrIndex;
  @Input() suggestedFields: Array<SuggestedSolrField>;

  @Output() openDeleteConfirmModal: EventEmitter<any> = new EventEmitter();
  @Output() showErrorMsg: EventEmitter<string> = new EventEmitter();
  @Output() solrIndicesChange: EventEmitter<string> = new EventEmitter();
  @Output() suggestedFieldsChange: EventEmitter<string> = new EventEmitter();

  constructor(
    private solrService: SolrService,
  ) {

  }

  ngOnInit() {
    console.log('In SuggestedFieldsListComponent :: ngOnInit');

  }

  ngOnChanges(changes: SimpleChanges): void {
    console.log('In SuggestedFieldsListComponent :: ngOnChanges');
  }


  lookupSuggestedFields() {
    console.log('In SuggestedFieldsListComponent :: lookupSuggestedFields');
    this.solrService.getSuggestedFields(this.solrIndex.id)
      .then(suggestedFields => {
        this.suggestedFields = suggestedFields;
      })
      .catch(error => this.showErrorMsg.emit(error));

  }

  deleteSuggestedField(suggestedFieldId: string, event: Event) {
    event.stopPropagation();
    const deleteCallback = () =>
      this.solrService
        .deleteSuggestedField(this.solrIndex.id, suggestedFieldId)
        .then(() => this.lookupSuggestedFields())

        .catch(error => this.showErrorMsg.emit(error));


    this.openDeleteConfirmModal.emit({ deleteCallback });
  }
}
