<template>
  <div>
    <div v-if="noTranscript === true">
      No transcript found for this asset
    </div>
    <div v-if="isBusy">
      <b-spinner
        variant="secondary"
        label="Loading..."
      />
      <p class="text-muted">
        (Loading...)
      </p>
    </div>
    <div v-else>
      <div v-if="isProfane">
        <span style="color:red">WARNING: Transcript contains potentially offensive words.</span>
        <br>
        <br>
      </div>
      <!--
      {{ transcript }}
      -->
      <div class="wrapper">
        <br>
        <template v-for="label in sorted_unique_labels">
          <b-button
            v-b-tooltip.hover
            variant="outline-secondary"
            :title="label[0]"
            size="sm"
            pill
            @click="goto_video_position(label[2])"
          >
            {{ label[0] }}
          </b-button> &nbsp;
        </template>
      </div>
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex'

export default {
  name: "Transcript",
  data() {
    return {
      transcript: "",
      elasticsearch_data: [],
      isBusy: false,
      operator: "transcript",
      noTranscript: false
    }
  },
  computed: {
    ...mapState(['player']),
    sorted_unique_labels() {
      // This function sorts and counts unique labels for mouse over events on label buttons
      const es_data = this.elasticsearch_data;
      const unique_labels = new Array(); //Map();
      // sort and count unique labels for label mouse over events
      es_data.forEach(function (record) {
        //unique_labels.set(record.content, record.index, record.start_time);
        unique_labels.push([record.content, record.index, record.start_time]);
      }.bind(this));
      const sorted_unique_labels = unique_labels.sort((a, b) => a[1] - b[1]); //new Map([...unique_labels.entries()].slice().sort((a, b) => a[1] - b[1]));
      // If Elasticsearch returned undefined labels then delete them:
      //sorted_unique_labels.delete(undefined);
      return sorted_unique_labels
    },
    isProfane() {
      const Filter = require('bad-words');
      const profanityFilter = new Filter({ placeHolder: '_' });
      return profanityFilter.isProfane(this.transcript);
    },
  },
  deactivated: function () {
    console.log('deactivated component:', this.operator)
  },
  activated: function () {
    console.log('activated component:', this.operator);
    this.fetchAssetData();
  },
  beforeDestroy: function () {
      this.transcript = ''
  },
  methods: {
    async fetchAssetData () {
      let query1 = 'AssetId:'+this.$route.params.asset_id+ ' _index:mietranscriptiontime';
      let apiName1 = 'mieElasticsearch';
      let path1 = '/_search';
      let apiParams1 = {
        headers: {'Content-Type': 'application/json'},
        queryStringParameters: {'q': query1, 'default_operator': 'AND', 'size': 10000}
      };
      let response1 = await this.$Amplify.API.get(apiName1, path1, apiParams1);
      if (!response1) {
        this.showElasticSearchAlert = true
      }
      else {
        let result1 = await response1;
        // console.log(result1);
        let data1 = result1.hits.hits;
        let es_data = [];
        if (data1.length === 0) {
          this.noTranscript = true
        }
        else {
          this.noTranscript = false;
          for (let i = 0, len = data1.length; i < len; i++) {
            let item = data1[i]._source;
            es_data.push({"content": item.content, "index": item.index, "start_time": parseFloat(item.start_time)});
          }
        }
        this.elasticsearch_data = JSON.parse(JSON.stringify(es_data));
      }

      let query = 'AssetId:'+this.$route.params.asset_id+ ' _index:mietranscript';
      let apiName = 'mieElasticsearch';
      let path = '/_search';
      let apiParams = {
        headers: {'Content-Type': 'application/json'},
        queryStringParameters: {'q': query, 'default_operator': 'AND', 'size': 10000}
      };
      let response = await this.$Amplify.API.get(apiName, path, apiParams);
      if (!response) {
        this.showElasticSearchAlert = true
      }
      else {
        let result = await response;
        // console.log(result);
        let data = result.hits.hits;
        if (data.length === 0) {
          this.noTranscript = true
        }
        else {
          this.noTranscript = false;
          for (let i = 0, len = data.length; i < len; i++) {
            this.transcript = data[i]._source.transcript
          }
        }
        this.isBusy = false
      }
    },
    goto_video_position(position) {
      this.player.currentTime(position / 1000);
    }
  }
}
</script>
