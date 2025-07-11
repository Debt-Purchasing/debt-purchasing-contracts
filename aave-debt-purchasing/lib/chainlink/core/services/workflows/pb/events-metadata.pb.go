// Code generated by protoc-gen-go. DO NOT EDIT.
// versions:
// 	protoc-gen-go v1.36.6
// 	protoc        v5.29.3
// source: events-metadata.proto

package pb

import (
	protoreflect "google.golang.org/protobuf/reflect/protoreflect"
	protoimpl "google.golang.org/protobuf/runtime/protoimpl"
	reflect "reflect"
	sync "sync"
	unsafe "unsafe"
)

const (
	// Verify that this generated code is sufficiently up-to-date.
	_ = protoimpl.EnforceVersion(20 - protoimpl.MinVersion)
	// Verify that runtime/protoimpl is sufficiently up-to-date.
	_ = protoimpl.EnforceVersion(protoimpl.MaxVersion - 20)
)

type WorkflowMetadata struct {
	state               protoimpl.MessageState `protogen:"open.v1"`
	WorkflowName        string                 `protobuf:"bytes,1,opt,name=workflowName,proto3" json:"workflowName,omitempty"`
	Version             string                 `protobuf:"bytes,2,opt,name=version,proto3" json:"version,omitempty"`
	WorkflowID          string                 `protobuf:"bytes,3,opt,name=workflowID,proto3" json:"workflowID,omitempty"`
	WorkflowExecutionID string                 `protobuf:"bytes,4,opt,name=workflowExecutionID,proto3" json:"workflowExecutionID,omitempty"`
	DonID               int32                  `protobuf:"varint,5,opt,name=donID,proto3" json:"donID,omitempty"`
	DonF                int32                  `protobuf:"varint,6,opt,name=donF,proto3" json:"donF,omitempty"`
	DonN                int32                  `protobuf:"varint,7,opt,name=donN,proto3" json:"donN,omitempty"`
	DonQ                int32                  `protobuf:"varint,8,opt,name=donQ,proto3" json:"donQ,omitempty"`
	P2PID               string                 `protobuf:"bytes,9,opt,name=p2pID,proto3" json:"p2pID,omitempty"`
	unknownFields       protoimpl.UnknownFields
	sizeCache           protoimpl.SizeCache
}

func (x *WorkflowMetadata) Reset() {
	*x = WorkflowMetadata{}
	mi := &file_events_metadata_proto_msgTypes[0]
	ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
	ms.StoreMessageInfo(mi)
}

func (x *WorkflowMetadata) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*WorkflowMetadata) ProtoMessage() {}

func (x *WorkflowMetadata) ProtoReflect() protoreflect.Message {
	mi := &file_events_metadata_proto_msgTypes[0]
	if x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

// Deprecated: Use WorkflowMetadata.ProtoReflect.Descriptor instead.
func (*WorkflowMetadata) Descriptor() ([]byte, []int) {
	return file_events_metadata_proto_rawDescGZIP(), []int{0}
}

func (x *WorkflowMetadata) GetWorkflowName() string {
	if x != nil {
		return x.WorkflowName
	}
	return ""
}

func (x *WorkflowMetadata) GetVersion() string {
	if x != nil {
		return x.Version
	}
	return ""
}

func (x *WorkflowMetadata) GetWorkflowID() string {
	if x != nil {
		return x.WorkflowID
	}
	return ""
}

func (x *WorkflowMetadata) GetWorkflowExecutionID() string {
	if x != nil {
		return x.WorkflowExecutionID
	}
	return ""
}

func (x *WorkflowMetadata) GetDonID() int32 {
	if x != nil {
		return x.DonID
	}
	return 0
}

func (x *WorkflowMetadata) GetDonF() int32 {
	if x != nil {
		return x.DonF
	}
	return 0
}

func (x *WorkflowMetadata) GetDonN() int32 {
	if x != nil {
		return x.DonN
	}
	return 0
}

func (x *WorkflowMetadata) GetDonQ() int32 {
	if x != nil {
		return x.DonQ
	}
	return 0
}

func (x *WorkflowMetadata) GetP2PID() string {
	if x != nil {
		return x.P2PID
	}
	return ""
}

var File_events_metadata_proto protoreflect.FileDescriptor

const file_events_metadata_proto_rawDesc = "" +
	"\n" +
	"\x15events-metadata.proto\x12\x02pb\"\x8a\x02\n" +
	"\x10WorkflowMetadata\x12\"\n" +
	"\fworkflowName\x18\x01 \x01(\tR\fworkflowName\x12\x18\n" +
	"\aversion\x18\x02 \x01(\tR\aversion\x12\x1e\n" +
	"\n" +
	"workflowID\x18\x03 \x01(\tR\n" +
	"workflowID\x120\n" +
	"\x13workflowExecutionID\x18\x04 \x01(\tR\x13workflowExecutionID\x12\x14\n" +
	"\x05donID\x18\x05 \x01(\x05R\x05donID\x12\x12\n" +
	"\x04donF\x18\x06 \x01(\x05R\x04donF\x12\x12\n" +
	"\x04donN\x18\a \x01(\x05R\x04donN\x12\x12\n" +
	"\x04donQ\x18\b \x01(\x05R\x04donQ\x12\x14\n" +
	"\x05p2pID\x18\t \x01(\tR\x05p2pIDBCZAgithub.com/smartcontractkit/chainlink/core/services/workflows/pb/b\x06proto3"

var (
	file_events_metadata_proto_rawDescOnce sync.Once
	file_events_metadata_proto_rawDescData []byte
)

func file_events_metadata_proto_rawDescGZIP() []byte {
	file_events_metadata_proto_rawDescOnce.Do(func() {
		file_events_metadata_proto_rawDescData = protoimpl.X.CompressGZIP(unsafe.Slice(unsafe.StringData(file_events_metadata_proto_rawDesc), len(file_events_metadata_proto_rawDesc)))
	})
	return file_events_metadata_proto_rawDescData
}

var file_events_metadata_proto_msgTypes = make([]protoimpl.MessageInfo, 1)
var file_events_metadata_proto_goTypes = []any{
	(*WorkflowMetadata)(nil), // 0: pb.WorkflowMetadata
}
var file_events_metadata_proto_depIdxs = []int32{
	0, // [0:0] is the sub-list for method output_type
	0, // [0:0] is the sub-list for method input_type
	0, // [0:0] is the sub-list for extension type_name
	0, // [0:0] is the sub-list for extension extendee
	0, // [0:0] is the sub-list for field type_name
}

func init() { file_events_metadata_proto_init() }
func file_events_metadata_proto_init() {
	if File_events_metadata_proto != nil {
		return
	}
	type x struct{}
	out := protoimpl.TypeBuilder{
		File: protoimpl.DescBuilder{
			GoPackagePath: reflect.TypeOf(x{}).PkgPath(),
			RawDescriptor: unsafe.Slice(unsafe.StringData(file_events_metadata_proto_rawDesc), len(file_events_metadata_proto_rawDesc)),
			NumEnums:      0,
			NumMessages:   1,
			NumExtensions: 0,
			NumServices:   0,
		},
		GoTypes:           file_events_metadata_proto_goTypes,
		DependencyIndexes: file_events_metadata_proto_depIdxs,
		MessageInfos:      file_events_metadata_proto_msgTypes,
	}.Build()
	File_events_metadata_proto = out.File
	file_events_metadata_proto_goTypes = nil
	file_events_metadata_proto_depIdxs = nil
}
